# frozen_string_literal: true

module MaintenanceStats
  module Queries
    module Github
      class RepoReleasesQuery < BaseQuery
        RELEASES_QUERY = Rails.application.config.graphql.client.parse <<-GRAPHQL
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

        VALID_PARAMS = %i[owner repo_name end_date].freeze
        REQUIRED_PARAMS = %i[owner repo_name].freeze

        def self.client_type
          :v4
        end

        def query(params: {})
          validate_params(params)

          end_date = params.delete(:end_date)

          releases = nil

          has_next_page = true
          cursor = nil
          while has_next_page
            params[:cursor] = cursor if cursor.present?
            result = @client.query(RELEASES_QUERY, variables: params)

            # send back the releases we have so far if we encounter an error
            return releases if check_for_errors(result)

            has_next_page = result.data.repository.releases.page_info.has_next_page
            cursor = result.data.repository.releases.page_info.end_cursor

            # initialize releases if we have not started gathering data
            releases ||= []

            result.data.repository&.releases&.nodes&.each do |release|
              # if release is within our search window or we don't have a specific date window then add it to the list
              publish_date = DateTime.parse(release.published_at)
              if end_date.nil? || publish_date > end_date
                releases << release
              else
                break
              end
            end
          end

          releases
        end

        private

        def check_for_errors(result)
          result.data.nil? || result.errors.any? || result.data.errors.any?
        end
      end
    end
  end
end
