module RepoSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    #include Elasticsearch::Model::Callbacks

    FIELDS = ['full_name^2', 'exact_name^2', 'description', 'homepage', 'language', 'license']

    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mapping do
        indexes :full_name, :analyzer => 'snowball', :boost => 6
        indexes :exact_name, :index => :not_analyzed, :boost => 2

        indexes :description, :analyzer => 'snowball'
        indexes :homepage
        indexes :language, :index => :not_analyzed
        indexes :license, :index => :not_analyzed

        indexes :status, :index => :not_analyzed
        indexes :default_branch, :index => :not_analyzed
        indexes :source_name, :index => :not_analyzed
        indexes :has_readme, :index => :not_analyzed
        indexes :has_changelog, :index => :not_analyzed
        indexes :has_contributing, :index => :not_analyzed
        indexes :has_license, :index => :not_analyzed
        indexes :has_coc, :index => :not_analyzed
        indexes :has_threat_model, :index => :not_analyzed
        indexes :has_audit, :index => :not_analyzed

        indexes :created_at, type: 'date'
        indexes :updated_at, type: 'date'
        indexes :pushed_at, type: 'date'
        indexes :last_synced_at, type: 'date'

        indexes :owner_id, type: 'integer'
        indexes :size, type: 'integer'
        indexes :stargazers_count, type: 'integer'
        indexes :forks_count, type: 'integer'
        indexes :open_issues_count, type: 'integer'
        indexes :subscribers_count, type: 'integer'
        indexes :github_id, type: 'integer'
        indexes :github_contributions_count, type: 'integer'

        indexes :fork
        indexes :has_issues
        indexes :has_wiki
        indexes :has_pages
        indexes :private
      end
    end

    # after_save() { __elasticsearch__.index_document }

    def as_indexed_json(options = {})
      as_json methods: [:exact_name]
    end

    def exact_name
      full_name
    end

    def self.total
      Rails.cache.fetch 'github_repositories:total', :expires_in => 1.hour, race_condition_ttl: 2.minutes do
        __elasticsearch__.client.count(index: 'github_repositories')["count"]
      end
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
                 filter:{
                   bool: {
                     must: [
                       {
                         exists: {
                           "field" => "pushed_at"
                         }
                       }
                     ],
                     must_not: [
                       {
                         term: {
                          "fork" => true
                         }
                       },
                       {
                         term: {
                          "private" => true
                         }
                       },
                       {
                         term: {
                           "status" => "Removed"
                         }
                       }
                     ]
                  }
                }
              }
            },
            field_value_factor: {
              field: "stargazers_count",
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
      search_definition[:sort]  = { (options[:sort] || '_score') => (options[:order] || 'desc') }
      search_definition[:track_scores] = true
      search_definition[:filter][:bool][:must] = filter_format(options[:filters])

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
        search_definition[:sort]  = [{'stargazers_count' => 'desc'}]
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
