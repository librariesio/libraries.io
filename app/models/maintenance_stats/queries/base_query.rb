# frozen_string_literal: true

module MaintenanceStats
  module Queries
    class BaseQuery
      # initialize with client
      # store the graphql queries in that class
      # query method that takes in hash for parameters and returns resultset

      VALID_PARAMS = [].freeze
      REQUIRED_PARAMS = [].freeze

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
        REQUIRED_PARAMS.each do |key|
          return false unless params.include? key
        end

        params.each do |key, _|
          return false unless VALID_PARAMS.include? key
        end
        true
      end

      private

      def valid_client_type?
        %i[v4 v3].include? self.class.client_type
      end
    end
  end
end
