module MaintenanceStats
    class CommitCountQuery < BaseQuery
        CommitCountsQuery = Rails.application.config.graphql.client.parse <<-'GRAPHQL'
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

        @@valid_params = [:owner, :name, :start_date]
        @@required_params = [:owner, :name, :start_date]

        def self.client_type
            :v4
        end

        def query(params: {})
            validate_params(params)

            @client.query(CommitCountsQuery, variables: params)
        end
    end

    class CommitCountQueryV3 < BaseQuery
        @@valid_params = [:full_name]
        @@required_params = [:full_name]

        def self.client_type
            :v3
        end

        def query(params: {})
            validate_params(params)

            @client.participation_stats(params[:full_name])
        end
    end
end
