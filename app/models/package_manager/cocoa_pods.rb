module PackageManager
  class CocoaPods < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = 'http://cocoapods.org/'
    COLOR = '#438eff'

    def self.package_link(project, version = nil)
      "http://cocoapods.org/pods/#{project.name}"
    end

    def self.documentation_url(name, version = nil)
      "http://cocoadocs.org/docsets/#{name}/#{version}"
    end

    def self.install_instructions(project, version = nil)
      "pod try #{project.name}"
    end

    def self.project_names
      get_json("http://cocoapods.libraries.io/pods.json")
    end

    def self.recent_names
      u = 'http://cocoapods.libraries.io/feed.rss'
      titles = SimpleRSS.parse(get_raw(u)).items.map(&:title)
      titles.map { |t| t.split(' ')[1] }.uniq
    end

    def self.project(name)
      versions = get_json("http://cocoapods.libraries.io/pods/#{name}.json")
      latest_version = versions.keys.sort_by{|version| version.split('.').map{|v| v.to_i}}.last
      versions[latest_version].merge('versions' => versions)
    end

    def self.mapping(project)
      {
        :name => project['name'],
        :description => project["summary"],
        :homepage => project["homepage"],
        :licenses => project["license"],
        :repository_url => repo_fallback(project['source']['git'], '')
      }
    end

    def self.versions(project)
      project['versions'].keys.map do |v|
        {
          :number => v.to_s
        }
      end
    end
  end
end
