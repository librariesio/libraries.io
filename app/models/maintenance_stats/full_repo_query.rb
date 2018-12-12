module MaintenanceStats
    class FullRepoQuery < BaseQuery
        FullRepoQuery = Rails.application.config.graphql.client.parse <<-'GRAPHQL'
            query($owner: String!, $repo_name: String!) {
                repository(owner: $owner, name: $repo_name) {
                    nameWithOwner
                    defaultBranchRef {
                        name
                        target {
                            ... on Commit {
                                history(first: 50) {
                                    edges {
                                        node {
                                            authoredDate
                                        }
                                    }
                                }
                            }
                        }
                    }
                    closedIssues: issues(states: CLOSED) {
                        totalCount
                    }
                    openIssues: issues(states: OPEN) {
                        totalCount
                    }
                    closedPullRequests: pullRequests(states: CLOSED) {
                        totalCount
                    }
                    openPullRequests: pullRequests(states: OPEN) {
                        totalCount
                    }
                    mergedPullRequests: pullRequests(states: MERGED) {
                        totalCount
                    }
                    releases(last: 1){
                        nodes{
                            publishedAt
                        }
                    }
                }
            }
        GRAPHQL

        @@valid_params = [:owner, :name]
        @@required_params = [:owner, :name]

        def self.client_type
            :v4
        end

        def query(params: {})
            validate_params(params)

            @client.query(FullRepoQuery, variables: params)
        end
    end
end
