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

        indexes :stargazers_count, type: 'integer'
        indexes :github_id, type: 'integer'
        indexes :github_contributions_count, type: 'integer'

        indexes :github_repository_language
        indexes :github_repository_license

        indexes :number
        indexes :labels, :analyzer => 'keyword'
        indexes :state

      end
    end

    after_save() { __elasticsearch__.index_document }

    def as_indexed_json(options = {})
      as_json methods: [:title, :github_contributions_count, :stars]
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
              }
            },
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
            must: [
               { "term": { "labels": "help wanted" }},
            ],
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
      search_definition[:sort]  = { (options[:sort] || '_score') => (options[:order] || 'desc') }
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
        search_definition[:sort]  = [{'stargazers_count' => 'desc'},
                                     {'created_at' => 'desc'},
                                     {'github_contributions_count' => 'asc'}]
      end

      __elasticsearch__.search(search_definition)
    end

    def self.filter_format(filters, except = nil)
      filters.select { |k, v| v.present? && k != except }.map do |k, v|
        {
          term: { k => v }
        }
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
