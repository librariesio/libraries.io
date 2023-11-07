# frozen_string_literal: true

module MaintenanceStats
  module Queries
    module Github
      class CommitCountQuery < BaseQuery
        COMMIT_COUNTS_QUERY = GithubGraphql.parse_query <<-GRAPHQL
          query ($owner: String!, $repo_name: String!, $one_week: GitTimestamp!, $one_month: GitTimestamp!, $two_months: GitTimestamp!, $one_year: GitTimestamp!) {
            repository(owner: $owner, name: $repo_name) {
              defaultBranchRef {
                target {
                  ... on Commit {
                    latestCommit: history(first: 1){
                      nodes {
                        committedDate
                      }
                    }
                    lastWeek: history(since: $one_week) {
                      totalCount
                    }
                    lastMonth: history(since: $one_month) {
                      totalCount
                    }
                    lastTwoMonths: history(since: $two_months) {
                      totalCount
                    }
                    lastYear: history(since: $one_year) {
                      totalCount
                    }
                  }
                }
                name
              }
            }
          }
        GRAPHQL

        VALID_PARAMS = %i[owner repo_name start_date].freeze
        REQUIRED_PARAMS = %i[owner repo_name start_date].freeze

        def self.client_type
          :v4
        end

        def query(params: {})
          validate_params(params)

          # generate the four dates needed
          start_date = params[:start_date]
          date_params = {
            one_week: (start_date - 1.week).iso8601,
            one_month: (start_date - 1.month).iso8601,
            two_months: (start_date - 2.months).iso8601,
            one_year: (start_date - 1.year).iso8601,
          }

          # merge params for query
          date_params.merge!(params.slice(:owner, :repo_name))

          @client.query(COMMIT_COUNTS_QUERY, variables: date_params)
        end
      end

      class CommitCountQueryV3 < BaseQuery
        VALID_PARAMS = [:full_name].freeze
        REQUIRED_PARAMS = [:full_name].freeze

        def self.client_type
          :v3
        end

        def query(params: {})
          validate_params(params)

          @client.participation_stats(params[:full_name])
        end
      end
    end
  end
end
