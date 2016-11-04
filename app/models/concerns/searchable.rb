module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    FIELDS = ['name^2', 'exact_name^2', 'repo_name', 'description', 'homepage', 'language', 'keywords_array', 'normalized_licenses', 'platform']

    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mapping do
        indexes :name, :analyzer => 'snowball', :boost => 6
        indexes :exact_name, :index => :not_analyzed, :boost => 2

        indexes :description, :analyzer => 'snowball'
        indexes :homepage
        indexes :repository_url
        indexes :repo_name
        indexes :latest_release_number, :analyzer => 'keyword'
        indexes :keywords_array, :analyzer => 'keyword'
        indexes :language, :analyzer => 'keyword'
        indexes :normalized_licenses, :analyzer => 'keyword'
        indexes :platform, :analyzer => 'keyword'
        indexes :status, :index => :not_analyzed

        indexes :created_at, type: 'date'
        indexes :updated_at, type: 'date'
        indexes :latest_release_published_at, type: 'date'
        indexes :pushed_at, type: 'date'

        indexes :rank, type: 'integer'
        indexes :stars, type: 'integer'
        indexes :versions_count, type: 'integer'
        indexes :dependents_count, type: 'integer'
        indexes :github_repository_id, type: 'integer'
        indexes :github_contributions_count, type: 'integer'
      end
    end

    after_save() { __elasticsearch__.index_document }

    def as_indexed_json(_options)
      as_json methods: [:stars, :repo_name, :exact_name, :github_contributions_count, :pushed_at]
    end

    def exact_name
      name
    end

    def pushed_at
      github_repository.try(:pushed_at)
    end

    def self.total
      Rails.cache.fetch 'projects:total', :expires_in => 1.hour, race_condition_ttl: 2.minutes do
        __elasticsearch__.client.count(index: 'projects')["count"]
      end
    end

    def self.cta_search(filters, options = {})
      facet_limit = options.fetch(:facet_limit, 35)
      options[:filters] ||= []
      search_definition = {
        query: {
          function_score: {
            query: {
              filtered: {
                query: { match_all: {} },
                filter:{ bool: filters }
              }
            },
            field_value_factor: {
              field: "rank",
              "modifier": "square"
            }
          }
        },
        facets: facets_options(facet_limit, options),
        filter: { bool: { must: [] } }
      }
      search_definition[:filter][:bool][:must] = filter_format(options[:filters])
      search_definition[:sort]  = [{'github_contributions_count' => 'asc'}, {'rank' => 'desc'}]
      __elasticsearch__.search(search_definition)
    end

    def self.bus_factor_search(options = {})
      cta_search({
        must: [
          { range: { github_contributions_count: { lte: 5, gte: 1 } } }
        ],
        must_not: [
          { term: { "status" => "Removed" } },
          { term: { "status" => "Unmaintained" } }
        ]
      }, options)
    end

    def self.unlicensed_search(options = {})
      cta_search({
        must_not: [
          { exists: { field: "normalized_licenses" } },
          { term: { "status" => "Removed" } },
          { term: { "status" => "Unmaintained" } }
        ]
      }, options)
    end

    def self.facets_options(facet_limit, options)
      {
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
      }
    end

    def self.search(original_query, options = {})
      facet_limit = options.fetch(:facet_limit, 35)
      query = sanitize_query(original_query)
      options[:filters] ||= []
      search_definition = {
        query: {
          function_score: {
            query: {
              filtered: {
                 query: {match_all: {}},
                 filter:{
                   bool: {
                     must: [],
                     must_not: [
                       {
                         term: { "status" => "Removed" }
                       }
                     ]
                  }
                }
              }
            },
            field_value_factor: {
              field: "rank",
              "modifier": "square"
            }
          }
        },
        facets: {
          platforms: facet_filter(:platform, facet_limit, options),
          languages: facet_filter(:language, facet_limit, options),
          keywords: facet_filter(:keywords_array, facet_limit, options),
          licenses: facet_filter(:normalized_licenses, facet_limit, options)
        },
        filter: { bool: { must: [] } },
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
                  operator: 'and'
                }
              }
            ]
          }
        }
      elsif options[:sort].blank?
        search_definition[:sort]  = [{'rank' => 'desc'}, {'stars' => 'desc'}]
      end

      if options[:prefix].present?
        search_definition[:query][:function_score][:query][:filtered][:query] = {
          prefix: { exact_name: original_query }
        }
        search_definition[:sort]  = [{'rank' => 'desc'}, {'stars' => 'desc'}]
      end

      __elasticsearch__.search(search_definition)
    end

    def self.filter_format(filters, except = nil)
      filters.select { |k, v| v.present? && k != except }.map do |k, v|
        Array(v).map { { terms: { k => v.split(',') } } }
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

    def self.facet_filter(name, limit, options)
      {
        terms: {
          field: name.to_s,
          size: limit
        },
        facet_filter: {
          bool: {
            must: filter_format(options[:filters], name.to_sym)
          }
        }
      }
    end
  end
end
