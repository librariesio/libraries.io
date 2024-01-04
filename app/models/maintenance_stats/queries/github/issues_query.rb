# frozen_string_literal: true

module MaintenanceStats
  module Queries
    module Github
      class IssuesQuery < BaseQuery
        ISSUES_QUERY = GithubGraphql.parse_query <<-GRAPHQL
          query($owner: String!, $repo_name: String!, $open_pr_query: String!, $closed_pr_query: String!, $one_year: DateTime!){
            openPullRequests: search(query: $open_pr_query, type: ISSUE) {
              issueCount
            }
            closedPullRequests: search(query: $closed_pr_query, type: ISSUE) {
              issueCount
            }
            repository(owner: $owner, name: $repo_name){
              openIssues: issues(states: OPEN, filterBy:{since:$one_year}) {
                totalCount
              },
              closedIssues:issues(states:CLOSED, filterBy:{since:$one_year}){
                totalCount
              },
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
          # figure out the one year ago
          params[:one_year] = (params[:start_date] - 1.year).iso8601
          # workaround lack of things in the main apis by using searches for PRs
          params[:open_pr_query] = "repo:#{params[:owner]}/#{params[:repo_name]} is:pr is:open created:>#{params[:one_year].to_date}"
          params[:closed_pr_query] = "repo:#{params[:owner]}/#{params[:repo_name]} is:pr is:closed created:>#{params[:one_year].to_date}"

          results = @client.query(ISSUES_QUERY, variables: params)
          QueryUtils.check_for_graphql_errors(results)

          results
        end
      end
    end
  end
end
