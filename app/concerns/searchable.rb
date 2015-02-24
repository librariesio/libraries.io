module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mapping do
        indexes :name, :analyzer => 'snowball', :boost => 10
        indexes :description, :analyzer => 'snowball'
        indexes :homepage
        indexes :repository_url
        indexes :keywords
        indexes :repo_name
        indexes :language, :analyzer => 'keyword'
        indexes :normalized_licenses, :analyzer => 'keyword'
        indexes :platform, :analyzer => 'keyword'

        indexes :created_at, type: 'date'
        indexes :updated_at, type: 'date'

        indexes :rank, type: 'integer'
        indexes :stars, type: 'integer'
        indexes :github_repository_id, type: 'integer'
      end
    end

    after_commit on: [:create] do
      __elasticsearch__.index_document
    end

    after_commit on: [:update] do
      __elasticsearch__.update_document
    end

    after_commit on: [:destroy] do
      __elasticsearch__.delete_document
    end

    def as_indexed_json(options = {})
      as_json methods: [:stars, :language, :rank, :repo_name]
    end

    def self.total
      __elasticsearch__.client.count["count"]
    end

    def self.search(query, options = {})
      facet_limit = options.fetch(:facet_limit, 30)
      query = '*' if query.blank?
      search_definition = {
        query: {
          function_score: {
            query: {
              filtered: {
                 query: {query_string: {query: query}},
                 filter:{ bool: { must: [] } }
              }
            },
            field_value_factor: {
              field: "rank"
            }
          }
        },
        facets: {
          platforms: { terms: {
            field: "platform",
            size: facet_limit
          } },
          languages: { terms: {
            field: "language",
            size: facet_limit
          } },
          licenses: { terms: {
            field: "normalized_licenses",
            size: facet_limit
          } },
          keywords: { terms: {
            field: "keywords",
            size: facet_limit
          } }
        },
      }
      search_definition[:sort]  = { (options[:sort] || 'rank') => (options[:order] || 'desc') }
      search_definition[:track_scores] = true

      options[:filters] ||= []
      options[:filters].each do |k,v|
        if v.present?
          search_definition[:query][:function_score][:query][:filtered][:filter][:bool][:must] << {term: { k => v}}
        end
      end

      __elasticsearch__.search(search_definition)
    end
  end
end
