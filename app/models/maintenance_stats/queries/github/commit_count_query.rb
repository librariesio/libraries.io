module MaintenanceStats
  module Queries
    module Github
      class CommitCountQuery < BaseQuery
        COMMIT_COUNTS_QUERY = Rails.application.config.graphql.client.parse <<-GRAPHQL
          query ($owner: String!, $name: String!, $one_week: GitTimestamp!, $one_month: GitTimestamp!, $two_months: GitTimestamp!, $one_year: GitTimestamp!) {
            repository(owner: $owner, name: $name) {
              defaultBranchRef {
                target {
                  ... on Commit {
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

        VALID_PARAMS = [:owner, :name, :start_date]
        REQUIRED_PARAMS = [:owner, :name, :start_date]

        def self.client_type
          :v4
        end

        def query(params: {})
          validate_params(params)

          # generate the four dates needed
          date_params = Hash.new { |k,v| k[v] = v.iso8601 }
          start_date = params[:start_date]
          date_params[:one_week] = start_date - 1.week
          date_params[:one_month] = start_date - 1.month
          date_params[:two_months] = start_date - 2.months
          date_params[:one_year] = start_date - 1.year

          # merge params for query
          date_params.merge!(params.slice(:owner, :name))

          @client.query(COMMIT_COUNTS_QUERY, variables: date_params)
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
