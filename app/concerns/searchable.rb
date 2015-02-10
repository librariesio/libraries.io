module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mapping do
        indexes :name, :analyzer => 'snowball', :boost => 10
        indexes :description, :analyzer => 'snowball', :boost => 5
        indexes :homepage
        indexes :repository_url
        indexes :language, :analyzer => 'keyword'
        indexes :normalized_licenses, :analyzer => 'keyword'
        indexes :platform, :analyzer => 'keyword'

        indexes :created_at, type: 'date'
        indexes :updated_at, type: 'date'

        indexes :stars, type: 'integer'
        indexes :github_repository_id, type: 'integer'
      end
    end

    after_commit on: [:create, :update] do
      __elasticsearch__.index_document
    end

    def as_indexed_json(options={})
      as_json methods: [:stars, :language]
    end

    def self.search(query, options={})
      query = '*' if query.blank?
      search_definition = {
        query: { query_string: { query: query } },
        filter: { bool: { must: [] } },
        facets: {
          platforms: { terms: {
            field: "platform",
            size: 30
          } },
          languages: { terms: {
            field: "language",
            size: 30
          } },
          licenses: { terms: {
            field: "normalized_licenses",
            size: 42
          } }
        }
      }
      if options[:sort]
        search_definition[:sort]  = { options[:sort] => (options[:order] || 'desc') }
        search_definition[:track_scores] = true
      end

      options[:filters] ||= []
      options[:filters].each do |k,v|
        if v.present?
          search_definition[:filter][:bool][:must] << {term: { k => v}}
        end
      end

      __elasticsearch__.search(search_definition)
    end
  end
end
