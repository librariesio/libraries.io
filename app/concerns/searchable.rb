module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    FIELDS = ['name^2', 'exact_name^2', 'repo_name', 'description', 'homepage', 'language', 'keywords_array', 'normalized_licenses', 'platform']

    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mapping do
        indexes :name, :analyzer => 'snowball', :boost => 6
        indexes :exact_name, :index => :not_analyzed, :boost => 100

        indexes :description, :analyzer => 'snowball'
        indexes :homepage
        indexes :repository_url
        indexes :repo_name
        indexes :latest_release_number, :analyzer => 'keyword'
        indexes :keywords_array, :analyzer => 'keyword'
        indexes :language, :analyzer => 'keyword'
        indexes :normalized_licenses, :analyzer => 'keyword'
        indexes :platform, :analyzer => 'keyword'

        indexes :created_at, type: 'date'
        indexes :updated_at, type: 'date'
        indexes :latest_release_published_at, type: 'date'

        indexes :rank, type: 'integer'
        indexes :stars, type: 'integer'
        indexes :versions_count, type: 'integer'
        indexes :dependents_count, type: 'integer'
        indexes :github_repository_id, type: 'integer'
      end
    end

    after_touch() { __elasticsearch__.update_document }

    def as_indexed_json(options = {})
      as_json methods: [:stars, :language, :repo_name, :exact_name]
    end

    def exact_name
      name
    end

    def self.total
      Rails.cache.fetch 'projects:total', :expires_in => 3.hour do
        __elasticsearch__.client.count(index: 'projects')["count"]
      end
    end

    def self.search(query, options = {})
      facet_limit = options.fetch(:facet_limit, 30)
      query = sanitize_query(query)
      options[:filters] ||= []
      search_definition = {
        query: {
          function_score: {
            query: {
              filtered: {
                 query: {match_all: {}},
                 filter:{ bool: { must: [] } }
              }
            },
            field_value_factor: {
              field: "rank",
              "modifier": "log1p"
            }
          }
        },
        facets: {
          platforms: { terms: {
            field: "platform",
            size: facet_limit},
            facet_filter: {
              bool: {
                must: filter_format(options[:filters], :platform)
              }
            }
          },
          languages: { terms: {
              field: "language",
              size: facet_limit
            },
            facet_filter: {
              bool: {
                must: filter_format(options[:filters], :language)
              }
            }
          },
          keywords: {
            terms: {
              field: "keywords_array",
              size: facet_limit
            },
            facet_filter: {
              bool: {
                must: filter_format(options[:filters], :keywords_array)
              }
            }
          },
          licenses: {
            terms: {
              field: "normalized_licenses",
              size: facet_limit
            },
            facet_filter: {
              bool: {
                must: filter_format(options[:filters], :normalized_licenses)
              }
            }
          }
        },
        filter: {
          bool: {
            must: []
          }
        },
        suggest: {
          did_you_mean: {
            text: query,
            term: {
              size: 1,
              field: "name"
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
                  operator: 'or'
                }
              }
            ]
          }
        }
      elsif options[:sort].blank?
        search_definition[:sort]  = [{'rank' => 'desc'}, {'stars' => 'desc'}]
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
