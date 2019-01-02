module MaintenanceStats
    module Queries
        class BaseQuery
            #initialize with client
            # store the graphql queries in that class
            # query method that takes in hash for parameters and returns resultset

            @@valid_params = []
            @@required_params = []

            def initialize(client)
                @client = client

                raise Error("Client type is not set or invalid") unless valid_client_type?
            end

            def query(params: {})
                raise NoMethodError("This should be overwritten")
            end

            def self.client_type
                raise NoMethodError("This should be overwritten with :v3 or :v4")
            end

            def validate_params(params)
                @@required_params.each do |key|
                    return false unless params.include? key
                end

                params.each do |key, _|
                    return false unless @@valid_params.include? key
                end
                true
            end

            private

            def valid_client_type?
                [:v4, :v3].include? self.class.client_type
            end
        end
    end
end