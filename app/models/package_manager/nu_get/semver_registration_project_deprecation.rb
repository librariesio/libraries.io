# frozen_string_literal: true

module PackageManager
  class NuGet
    class SemverRegistrationProjectDeprecation
      attr_reader :message, :alternate_package

      def initialize(message:, alternate_package:)
        @message = message
        @alternate_package = alternate_package
      end
    end
  end
end
