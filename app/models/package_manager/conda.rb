require 'uri'

module PackageManager
  class Conda < Base
    def self.project_names
      get_json("http://conda.libraries.io/packages")
    end

    def self.project(name)
      chanel, name = urlize_channel_name(name)
      versions = get_json("http://conda-parser.libraries.io/info/#{channel}/#{name}")
      latest_version = versions.keys.sort_by{|version| version.split('.').map{|v| v.to_i}}.last
      versions[latest_version].merge('versions' => versions)
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
