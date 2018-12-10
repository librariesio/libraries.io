module Queries
    FullRepoQuery = AuthToken.v4_client.parse <<-'GRAPHQL'
        query($owner: String!, $repo_name: String!) {
            repository(owner: $owner, name: $repo_name) {
                nameWithOwner
                forks {
                    totalCount
                }
                stargazers {
                    totalCount
                }
                watchers {
                    totalCount
                }
                createdAt
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
                description
                hasIssuesEnabled
                hasWikiEnabled
                homepageUrl
                isArchived
                isFork
                isMirror
                licenseInfo {
                    key
                }
                primaryLanguage {
                    name
                }
                pushedAt
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

    CommitCountsQuery = AuthToken.v4_client.parse <<-'GRAPHQL'
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

    ReleasesQuery = AuthToken.v4_client.parse <<-'GRAPHQL'
        query($owner: String!, $repo_name: String!, $cursor: String){
            repository(owner: $owner, name: $repo_name){
                releases(first: 100, after: $cursor, orderBy: {field: CREATED_AT, direction: DESC}){
                    nodes {
                        name
                        publishedAt
                    }
                    totalCount
                    pageInfo {
                        hasPreviousPage
                        hasNextPage
                        endCursor
                        startCursor
                    }
                }
            }
        }
    GRAPHQL

    class RepositoryContributorsQuery
        def self.repository_contributors(client, repo_name_with_owner)
            client.contribs(repo_name_with_owner)
        end
    end
end