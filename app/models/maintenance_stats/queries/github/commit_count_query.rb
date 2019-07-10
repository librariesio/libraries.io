module MaintenanceStats
  module Queries
    module Github
      class CommitCountQuery < BaseQuery
        COMMIT_COUNTS_QUERY = Rails.application.config.graphql.client.parse <<-GRAPHQL
          query($owner: String!, $repo_name: String!, $start_date: GitTimestamp!) {
            repository(owner: $owner, name: $repo_name) {
              defaultBranchRef {
                target {
                  ... on Commit {
                    history(since: $start_date) {
                      totalCount
                    }
                  }
                }
                name
              }
            }
          }
        GRAPHQL

        VALID_PARAMS = [:owner, :name, :start_date]
        REQUIRED_PARAMS = [:owner, :name, :start_date]

        def self.client_type
          :v4
        end

        def query(params: {})
          validate_params(params)

          @client.query(COMMIT_COUNTS_QUERY, variables: params)
        end
      end

      class CommitCountQueryV3 < BaseQuery
        VALID_PARAMS = [:full_name]
        REQUIRED_PARAMS = [:full_name]

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
