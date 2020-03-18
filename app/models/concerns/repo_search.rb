# frozen_string_literal: true

module RepoSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    index_name "repositories-#{Rails.env}"

    FIELDS = ["full_name^2", "exact_name^2", "description", "homepage", "language", "license"].freeze

    settings index: { number_of_shards: 3, number_of_replicas: 1 } do
      mapping do
        indexes :full_name, type: "string", analyzer: "snowball", boost: 6
        indexes :exact_name, type: "string", index: :not_analyzed, boost: 2

        indexes :description, type: "string", analyzer: "snowball"
        indexes :homepage, type: "string"
        indexes :language, type: "string", index: :not_analyzed
        indexes :license, type: "string", index: :not_analyzed
        indexes :keywords, type: "string", index: :not_analyzed
        indexes :host_type, type: "string", index: :not_analyzed

        indexes :status, type: "string", index: :not_analyzed

        indexes :created_at, type: "date"
        indexes :updated_at, type: "date"
        indexes :pushed_at, type: "date"

        indexes :stargazers_count, type: "integer"
        indexes :forks_count, type: "integer"
        indexes :open_issues_count, type: "integer"
        indexes :subscribers_count, type: "integer"
        indexes :contributions_count, type: "integer"
        indexes :rank, type: "integer"

        indexes :fork, type: "boolean"
        indexes :private, type: "boolean"
      end
    end

    after_commit -> { __elasticsearch__.index_document if previous_changes.any? }, on: %i[create update], prepend: true
    after_commit lambda {
                   begin
                            __elasticsearch__.delete_document
                   rescue StandardError
                     nil
                          end
                 }, on: :destroy

    def self.facets(options = {})
      Rails.cache.fetch "repo_facet:#{options.to_s.gsub(/\W/, '')}", expires_in: 1.hour, race_condition_ttl: 2.minutes do
        search("", options).response.aggregations
      end
    end

    def as_indexed_json(_options = {})
      as_json methods: %i[exact_name keywords rank]
    end

    def rank
      read_attribute(:rank) || 0
    end

    def exact_name
      full_name
    end

    def self.search(query, options = {})
      facet_limit = options.fetch(:facet_limit, 35)
      options[:filters] ||= []
      options[:must_not] ||= []
      search_definition = {
        query: {
          function_score: {
            query: {
              filtered: {
                query: { match_all: {} },
                filter: {
                  bool: {
                    must: [],
                    must_not: [
                      {
                        term: {
                          "fork" => true,
                        },
                      },
                      {
                        term: {
                          "private" => true,
                        },
                      },
                      {
                        term: {
                          "status" => "Removed",
                        },
                      },
                      {
                        term: {
                          "status" => "Hidden",
                        },
                      },
                    ],
                  },
                },
              },
            },
            field_value_factor: {
              field: "rank",
              "modifier": "square",
            },
          },
        },
        filter: {
          bool: {
            must_not: options[:must_not],
          },
        },
      }

      unless options[:api]
        unless options[:no_facet]
          search_definition[:aggs] = {
            language: Project.facet_filter(:language, facet_limit, options),
            license: Project.facet_filter(:license, facet_limit, options),
            keywords: Project.facet_filter(:keywords, facet_limit, options),
            host_type: Project.facet_filter(:host_type, facet_limit, options),
          }
        end
        if query.present?
          search_definition[:suggest] = {
            did_you_mean: {
              text: query,
              term: {
                size: 1,
                field: "full_name",
              },
            },
          }
        end
      end

      search_definition[:sort] = { (options[:sort] || "_score") => (options[:order] || "desc") }
      search_definition[:query][:function_score][:query][:filtered][:filter][:bool][:must] = Project.filter_format(options[:filters])

      if query.present?
        search_definition[:query][:function_score][:query][:filtered][:query] = Project.query_options(query, FIELDS)
      elsif options[:sort].blank?
        search_definition[:sort] = [{ "rank" => "desc" }, { "stargazers_count" => "desc" }]
      end

      __elasticsearch__.search(search_definition)
    end
  end
end
