module MaintenanceStats
    module Queries
        class RepoReleasesQuery < BaseQuery
            ReleasesQuery = Rails.application.config.graphql.client.parse <<-'GRAPHQL'
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

            @@valid_params = [:owner, :repo_name, :end_date]
            @@required_params = [:owner, :repo_name]

            def self.client_type
                :v4
            end

            def query(params: {})
                validate_params(params)

                end_date = params.slice(:end_date)
                params = params.slice!(:end_date)

                @releases = nil

                page_info = { has_next_page: true, cursor: nil}
                while(page_info[:has_next_page])
                    params[:cursor] = page_info[:cursor] if page_info[:cursor]
                    result = @client.query(ReleasesQuery, variables: params)

                    if check_for_errors(result)
                        @releases = result if @releases.nil?
                        return @releases
                    end

                    has_next_page = result.data.repository.releases.page_info.has_next_page
                    cursor = result.data.repository.releases.page_info.end_cursor
                    page_info = { has_next_page: has_next_page, cursor: cursor}

                    if @releases.nil?
                        @releases = result
                        next
                    end
                    
                    result.data.repository&.releases.nodes.each do |release|
                        publish_date = DateTime.parse(release.published_at)
                        if publish_date > end_date
                            @releases.data.repository.releases.nodes << release
                        else
                            has_next_page = false
                            break
                        end
                    end
                    
                end

                @releases
            end

            private

            def check_for_errors(result)
                return result.data.nil? || result.errors.any? || result.data.errors.any?
            end
        end
    end
end
