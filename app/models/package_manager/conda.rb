require 'uri'

module PackageManager
  class Conda < Base
    def self.project_names
      get_json("http://conda.libraries.io/packages")
    end

    def self.project(name)
      chanel, name = urlize_channel_name(name)
      latest_version = URI.escape(get_json("http://conda.libraries.io/packages/#{channel}/#{name}"))
      latest_version_data = get_json("http://conda-parser.libraries.io/info/#{channel}/#{name}/#{latest_version}")

      latest_version_data
    end

    def self.mapping(project)
      {
      }
    end

    private

    def self.urlize_channel_name(name)
      channel = name.rpartition('/').first
      name = name.rpartition('/').last

      [
        URI.escape(URI.escape(channel)),
        name
      ]
    end
  end
end
