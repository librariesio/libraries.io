# frozen_string_literal: true
module IssueSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    index_name    "issues-#{Rails.env}"

    FIELDS = ['title^2', 'body']

    settings index: { number_of_shards: 3, number_of_replicas: 1 } do
      mapping do
        indexes :title, type: 'string', analyzer: 'snowball', boost: 6

        indexes :created_at, type: 'date'
        indexes :contributions_count, type: 'integer'
        indexes :rank, type: 'integer'
        indexes :comments_count, type: 'integer'

        indexes :language, type: 'string', analyzer: 'keyword'
        indexes :license, type: 'string', analyzer: 'keyword'

        indexes :locked, type: 'boolean'
        indexes :labels, type: 'string', analyzer: 'keyword'
        indexes :state, type: 'string', analyzer: 'keyword'

        indexes :host_type, type: 'string', index: :not_analyzed
      end
    end

    after_save lambda { __elasticsearch__.index_document  }
    after_commit lambda { __elasticsearch__.delete_document rescue nil },  on: :destroy

    def as_indexed_json(_options = {})
      as_json methods: [:contributions_count, :language, :license, :rank]
    end

    def self.search(options = {})
      options[:filters] ||= []
      options[:must_not] ||= []

      search_definition = {
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
        aggs: issues_facet_filters(options, options[:labels_to_keep]),
        filter: { bool: { must: [], must_not: options[:must_not] } },
        sort: default_sort
      }
      search_definition[:filter][:bool][:must] = filter_format(options[:filters]) if options[:filters].any?
      if options[:repo_ids].present?
        search_definition[:query][:filtered][:filter][:bool][:must] << {
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
        aggs: issues_facet_filters(options, Issue::FIRST_PR_LABELS),
        filter: { bool: { must: [], must_not: options[:must_not] } },
        sort: default_sort
      }
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
          aggs: {
            language: {
              terms: { field: "language", size: facet_limit }
            }
          },
          filter: {
            bool: { must: filter_format(options[:filters], :language) }
          }
        },
        labels: {
          aggs: {
            labels: {
              terms: { field: "labels", size: facet_limit }
            }
          },
          filter: {
            bool: { must: label_filter_format(options[:filters], labels) }
          }
        },
        license: {
          aggs: {
            license: {
              terms: { field: "license", size: facet_limit }
            }
          },
          filter: {
            bool: { must: filter_format(options[:filters], :license) }
          }
        }
      }
    end

    def self.label_filter_format(filters, labels_to_keep = ['help wanted'])
      labels_to_keep ||= ['help wanted']
      filters.select { |_k, v| v.present? }.map do |k, v|
        if k == :labels
          Array(labels_to_keep).map { |value| { terms: { k => value.split(',') } } }
        else
          Array(v).map { { terms: { k => v.split(',') } } }
        end
      end
    end
  end
end
