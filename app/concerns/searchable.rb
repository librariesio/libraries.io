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
        indexes :normalized_licenses, :analyzer => 'keyword'
        indexes :platform, :analyzer => 'keyword'

        indexes :created_at
        indexes :updated_at
      end
    end

    after_commit on: [:create, :update] do
      __elasticsearch__.index_document
    end

    # Customize the JSON serialization for Elasticsearch
    #
    # def as_indexed_json(options={})
    #   hash = self.as_json(
    #     include: { authors:    { methods: [:full_name], only: [:full_name] },
    #                comments:   { only: [:body, :stars, :pick, :user, :user_location] }
    #              })
    #   hash['categories'] = self.categories.map(&:title)
    #   hash
    # end

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
          licenses: { terms: {
            field: "normalized_licenses",
            size: 30
          } }
        }
      }
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
