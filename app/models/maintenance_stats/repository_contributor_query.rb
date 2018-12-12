module MaintenanceStats
    class RepositoryContributorsQuery < BaseQuery
        @@valid_params = [:full_name]
        @@required_params = [:full_name]

        def self.client_type
            :v3
        end

        def query(params: {})
            validate_params(params)

            @client.contribs(params[:full_name])
        end
    end
end
