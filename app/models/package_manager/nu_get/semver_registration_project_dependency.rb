module PackageManager
  class NuGet
    class SemverRegistrationProjectDependency
      attr_reader :name, :requirements

      def initialize(name:, requirements:)
        @name = name
        @requirements = requirements
      end
    end
  end
end
