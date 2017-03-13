module IssueSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    index_name    "github_issues"
    document_type "github_issue"

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
        indexes :rank, type: 'integer'
        indexes :comments_count, type: 'integer'

        indexes :language, :analyzer => 'keyword'
        indexes :license, :analyzer => 'keyword'

        indexes :number
        indexes :locked
        indexes :labels, :analyzer => 'keyword'
        indexes :state, :analyzer => 'keyword'
      end
    end

    after_save lambda { __elasticsearch__.index_document  }
    after_commit lambda { __elasticsearch__.delete_document rescue nil },  on: :destroy

    def as_indexed_json(_options)
      as_json methods: [:title, :contributions_count, :stars, :language, :license, :rank]
    end

    def exact_title
      full_title
    end

    def self.search(options = {})
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
                     must: [ { "term": { "state": "open"}}, { "term": { "locked": false}} ],
                     must_not: [ { term: { "labels": "wontfix" } } ],
                   }
                 }
              }
            },
            field_value_factor: { field: "rank", "modifier": "square" }
          }
        },
        # facets: issues_facet_filters(options, options[:labels_to_keep]),
        filter: { bool: { must: [], must_not: options[:must_not] } }
      }
      search_definition[:track_scores] = true
      search_definition[:sort] = default_sort if options[:sort].blank?
      search_definition[:filter][:bool][:must] = filter_format(options[:filters])
      if options[:repo_ids].present?
        search_definition[:query][:function_score][:query][:filtered][:filter][:bool][:must] << {
          terms: { "repository_id": options[:repo_ids] } }
      end
      __elasticsearch__.search(search_definition)
    end

    def self.filter_format(filters, except = nil)
      filters.select { |k, v| v.present? && k != except }.map do |k, v|
        if v.is_a?(Array)
          v.map { |value| { term: { k => value } } }
        else
          { term: { k => v } }
        end
      end.flatten
    end

    def self.first_pr_search(options = {})
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
                     must: [ { "term": { "state": "open"}}, { "term": { "locked": false}} ],
                     must_not: [ { term: { "labels": "wontfix" } } ],
                     should: Issue::FIRST_PR_LABELS.map do |label|
                       { term: { "labels": label } }
                     end
                   }
                 }
              }
            },
            field_value_factor: { field: "rank", "modifier": "square" }
          }
        },
        # facets: issues_facet_filters(options, Issue::FIRST_PR_LABELS),
        filter: { bool: { must: [], must_not: options[:must_not] } }
      }
      search_definition[:track_scores] = true
      search_definition[:sort] = default_sort if options[:sort].blank?
      search_definition[:filter][:bool][:must] = filter_format(options[:filters])
      __elasticsearch__.search(search_definition)
    end

    def self.default_sort
      [{'comments_count' => 'asc'}, {'rank' => 'desc'}, {'created_at' => 'asc'}, {'contributions_count' => 'asc'}]
    end

    def self.issues_facet_filters(options, labels)
      facet_limit = options.fetch(:facet_limit, 35)
      {
        language: {
          terms: { field: "language", size: facet_limit },
          facet_filter: {
            bool: { must: filter_format(options[:filters], :language) }
          }
        },
        labels: {
          terms: { field: "labels", size: facet_limit },
          facet_filter: {
            bool: { must: label_filter_format(options[:filters], labels) }
          }
        },
        license: {
          terms: { field: "license", size: facet_limit },
          facet_filter: {
            bool: { must: filter_format(options[:filters], :license) }
          }
        }
      }
    end

    def self.label_filter_format(filters, labels_to_keep = ['help wanted'])
      labels_to_keep ||= ['help wanted']
      filters.select { |_k, v| v.present? }.map do |k, v|
        if k == :labels
          labels_to_keep.map { |value| { term: { k => value } } }
        else
          { term: { k => v } }
        end
      end
    end
  end
end
