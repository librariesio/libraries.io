module IssueSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks


    FIELDS = ['title^2', 'body']

    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mapping do
        indexes :title, :analyzer => 'snowball', :boost => 6

        indexes :created_at, type: 'date'
        indexes :updated_at, type: 'date'
        indexes :closed_at, type: 'date'

        indexes :stars, type: 'integer'
        indexes :github_id, type: 'integer'
        indexes :contributions_count, type: 'integer'

        indexes :language, :analyzer => 'keyword'
        indexes :license, :analyzer => 'keyword'

        indexes :number
        indexes :locked
        indexes :labels, :analyzer => 'keyword'
        indexes :state, :analyzer => 'keyword'

      end
    end

    after_save() { __elasticsearch__.index_document }

    def as_indexed_json(options = {})
      as_json methods: [:title, :contributions_count, :stars, :language, :license]
    end

    def exact_title
      full_title
    end

    def self.search(query, options = {})
      facet_limit = options.fetch(:facet_limit, 35)

      query = sanitize_query(query)
      options[:filters] ||= []
      options[:must_not] ||= []

      search_definition = {
        query: {
          function_score: {
            query: {
              filtered: {
                 query: {match_all: {}},
                 filter: {
                   bool: {
                     must: [
                        { "term": { "state": "open"}},
                        { "term": { "locked": false}}
                     ],
                     must_not: [
                       {
                         term: {
                          "labels": "wontfix"
                         }
                       }
                     ]
                   }
                 }
              }
            },
            field_value_factor: {
              field: "stars",
              "modifier": "square"
            }
          }
        },
        facets: {
          language: { terms: {
              field: "language",
              size: facet_limit
            },
            facet_filter: {
              bool: {
                must: filter_format(options[:filters], :language)
              }
            }
          },
          labels: {
            terms: {
              field: "labels",
              size: facet_limit
            },
            facet_filter: {
              bool: {
                must: label_filter_format(options[:filters], options[:labels_to_keep])
              }
            }
          },
          license: {
            terms: {
              field: "license",
              size: facet_limit
            },
            facet_filter: {
              bool: {
                must: filter_format(options[:filters], :license)
              }
            }
          }
        },
        filter: {
          bool: {
            must: [],
            must_not: options[:must_not]
          }
        },
        suggest: {
          did_you_mean: {
            text: query,
            term: {
              size: 1,
              field: "full_name"
            }
          }
        }
      }
      search_definition[:track_scores] = true

      if query.present?
        search_definition[:query][:function_score][:query][:filtered][:query] = {
          bool: {
            should: [
              { multi_match: {
                  query: query,
                  fields: FIELDS,
                  fuzziness: 1.2,
                  slop: 2,
                  type: 'cross_fields',
                  operator: 'and'
                }
              }
            ]
          }
        }
      elsif options[:sort].blank?
        search_definition[:sort]  = [{'comments_count' => 'asc'},
                                     {'stars' => 'desc'},
                                     {'created_at' => 'asc'},
                                     {'contributions_count' => 'asc'}]
      end
      search_definition[:filter][:bool][:must] = filter_format(options[:filters])
      __elasticsearch__.search(search_definition)
    end

    def self.first_pr_search(query, options = {})
      facet_limit = options.fetch(:facet_limit, 35)

      query = sanitize_query(query)
      options[:filters] ||= []
      options[:must_not] ||= []

      search_definition = {
        query: {
          function_score: {
            query: {
              filtered: {
                 query: {match_all: {}},
                 filter: {
                   bool: {
                     must: [
                        { "term": { "state": "open"}},
                        { "term": { "locked": false}}
                     ],
                     must_not: [
                       {
                         term: {
                          "labels": "wontfix"
                         }
                       }
                     ],
                     should: GithubIssue::FIRST_PR_LABELS.map do |label|
                       {
                         term: {
                          "labels": label
                         }
                       }
                     end
                   }
                 }
              }
            },
            field_value_factor: {
              field: "stars",
              "modifier": "square"
            }
          }
        },
        facets: {
          language: { terms: {
              field: "language",
              size: facet_limit
            },
            facet_filter: {
              bool: {
                must: filter_format(options[:filters], :language)
              }
            }
          },
          labels: {
            terms: {
              field: "labels",
              size: facet_limit
            },
            facet_filter: {
              bool: {
                must: label_filter_format(options[:filters], GithubIssue::FIRST_PR_LABELS)
              }
            }
          },
          license: {
            terms: {
              field: "license",
              size: facet_limit
            },
            facet_filter: {
              bool: {
                must: filter_format(options[:filters], :license)
              }
            }
          }
        },
        filter: {
          bool: {
            must: [],
            must_not: options[:must_not]
          }
        },
        suggest: {
          did_you_mean: {
            text: query,
            term: {
              size: 1,
              field: "full_name"
            }
          }
        }
      }
      search_definition[:track_scores] = true

      if query.present?
        search_definition[:query][:function_score][:query][:filtered][:query] = {
          bool: {
            should: [
              { multi_match: {
                  query: query,
                  fields: FIELDS,
                  fuzziness: 1.2,
                  slop: 2,
                  type: 'cross_fields',
                  operator: 'and'
                }
              }
            ]
          }
        }
      elsif options[:sort].blank?
        search_definition[:sort]  = [{'comments_count' => 'asc'},
                                     {'stars' => 'desc'},
                                     {'created_at' => 'asc'},
                                     {'contributions_count' => 'asc'}]
      end
      search_definition[:filter][:bool][:must] = filter_format(options[:filters])
      __elasticsearch__.search(search_definition)
    end

    def self.filter_format(filters, except = nil)
      filters.select { |k, v| v.present? && k != except }.map do |k, v|
        if v.is_a?(Array)
          v.map do |value|
            {
              term: { k => value }
            }
          end
        else
          {
            term: { k => v }
          }
        end
      end.flatten
    end

    def self.label_filter_format(filters, labels_to_keep = ['help wanted'])
      labels_to_keep ||= ['help wanted']
      filters.select { |k, v| v.present? }.map do |k, v|
        if k == :labels
          labels_to_keep.map do |value|
            {
              term: { k => value }
            }
          end
        else
          {
            term: { k => v }
          }
        end
      end
    end

    def self.sanitize_query(str)
      return '' if str.blank?
      # Escape special characters
      # http://lucene.apache.org/core/old_versioned_docs/versions/2_9_1/queryparsersyntax.html#Escaping Special Characters
      escaped_characters = Regexp.escape('\\+-&|/!(){}[]^~?:')
      str = str.gsub(/([#{escaped_characters}])/, '\\\\\1')

      # AND, OR and NOT are used by lucene as logical operators. We need
      # to escape them
      ['AND', 'OR', 'NOT'].each do |word|
        escaped_word = word.split('').map {|char| "\\#{char}" }.join('')
        str = str.gsub(/\s*\b(#{word.upcase})\b\s*/, " #{escaped_word} ")
      end

      # Escape odd quotes
      quote_count = str.count '"'
      str = str.gsub(/(.*)"(.*)/, '\1\"\3') if quote_count % 2 == 1

      str
    end
  end
end
