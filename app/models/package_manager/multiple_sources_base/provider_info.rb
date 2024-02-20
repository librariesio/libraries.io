# frozen_string_literal: true

module PackageManager
  class MultipleSourcesBase < Base
    class ProviderInfo
      attr_reader :identifier, :provider_class

      def initialize(identifier:, provider_class:, default: false)
        @identifier = identifier
        @provider_class = provider_class
        @default = default
      end

      def default?
        !!@default
      end
    end
  end
end
