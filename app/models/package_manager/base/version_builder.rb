# frozen_string_literal: true

module PackageManager
  class Base
    # This builder class only exists to ensure we have a defined set
    # of keys that we allow PackageManager::Base.versions() to return.
    class VersionBuilder
      MISSING = Object.new

      def self.build_hash(number:, status: MISSING, created_at: MISSING, published_at: MISSING, original_license: MISSING, dependencies: MISSING)
        hash = {
          number: number,
        }

        hash[:status] = status if status != MISSING
        # TODO: created_at might not be needed here, we're just passing it from Go.versions().
        hash[:created_at] = created_at if created_at != MISSING
        hash[:published_at] = published_at if published_at != MISSING
        hash[:original_license] = original_license if original_license != MISSING

        # This is really only a hack for PackageManager::NuGet.dependencies() because that method only accepts a
        # mapped project, but the raw project contains the dependencies. We could consider making this official
        # and adding a DependencyBuilder, so we could use mapped_project->versions->dependencies to set deps in Base.
        hash[:dependencies] = dependencies if dependencies != MISSING

        hash
      end
    end
  end
end
