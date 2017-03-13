module RepoSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    index_name    "github_repositories"
    document_type "github_repository"

    FIELDS = ['full_name^2', 'exact_name^2', 'description', 'homepage', 'language', 'license']

    settings index: { number_of_shards: 1, number_of_replicas: 0 } do
      mapping do
        indexes :full_name, :analyzer => 'snowball', :boost => 6
        indexes :exact_name, :index => :not_analyzed, :boost => 2

        indexes :description, :analyzer => 'snowball'
        indexes :homepage
        indexes :language, :index => :not_analyzed
        indexes :license, :index => :not_analyzed
        indexes :keywords, :index => :not_analyzed
        indexes :platforms, :index => :not_analyzed
        indexes :host_type, :index => :not_analyzed

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
        indexes :github_id, type: 'string'
        indexes :uuid, type: 'string'
        indexes :github_contributions_count, type: 'integer'
        indexes :contributions_count, type: 'integer'
        indexes :rank, type: 'integer'

        indexes :fork
        indexes :has_issues
        indexes :has_wiki
        indexes :has_pages
        indexes :private
      end
    end

    after_save lambda { __elasticsearch__.index_document }
    after_commit lambda { __elasticsearch__.delete_document rescue nil },  on: :destroy

    def self.facets(options = {})
      Rails.cache.fetch "repo_facet:#{options.to_s.gsub(/\W/, '')}", :expires_in => 1.hour, race_condition_ttl: 2.minutes do
        {}#search('', options).response.facets
      end
    end

    def as_indexed_json(_options)
      as_json methods: [:exact_name, :keywords, :platforms, :github_id, :github_contributions_count, :rank]
    end

    def rank
      read_attribute(:rank) || 0
    end

    def exact_name
      full_name
    end

    def keywords
      (project_keywords + readme_keywords).uniq.first(10)
    end

    def project_keywords
      projects.map(&:keywords_array).flatten.compact.uniq(&:downcase)
    end

    def readme_keywords
      return [] unless readme.present?
      readme.keywords
    end

    def platforms
      projects.map(&:platform).compact.uniq(&:downcase)
    end

    def self.search(query, options = {})
      facet_limit = options.fetch(:facet_limit, 35)
      query = Project.sanitize_query(query)
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
                     must: [],
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
              field: "rank",
              "modifier": "square"
            }
          }
        },
        # facets: {
        #   language: Project.facet_filter(:language, facet_limit, options),
        #   license: Project.facet_filter(:license, facet_limit, options),
        #   keywords: Project.facet_filter(:keywords, facet_limit, options),
        #   host_type: Project.facet_filter(:host_type, facet_limit, options)
        # },
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
      search_definition[:filter][:bool][:must] = Project.filter_format(options[:filters])

      if query.present?
        search_definition[:query][:function_score][:query][:filtered][:query] = Project.query_options(query, FIELDS)
      elsif options[:sort].blank?
        search_definition[:sort]  = [{'rank' => 'desc'}, {'stargazers_count' => 'desc'}]
      end

      __elasticsearch__.search(search_definition)
    end
  end
end
