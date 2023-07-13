module PackageManager
  class Pypi
    # A raw release coming from prior PackageManger data transformations,
    # converted to an object for clearer usage.
    #
    # For our current purposes, which is processing data about the list of
    # possible versions, the only data we need is the published_at date,
    # which may or may not exist.
    #
    # Right now the data for this is being fetched in another part of the
    # Pypi, specifically from the project endpoint. This gets us closer to
    # being able to break apart the Pypi code into something more moduler.
    class RawRelease
      attr_reader :number

      def initialize(number:, release:)
        @number = number
        @release = release
      end

      # PyPI can return an empty dataset for a single release. In that case,
      # we'll need to retrieve data about this release from other sources.
      def details?
        !@release.empty?
      end

      def published_at
        return nil unless details?

        upload_time = @release.dig(0, "upload_time")
        raise ArgumentError, "does not contain upload_time" unless upload_time

        upload_time ? Time.parse(upload_time) : nil
      end

      # Create an editable Version object
      def to_version
        PackageManager::Pypi::Version.new(number: number, published_at: published_at)
      end
    end
  end
end
