module PackageManager
  class CPAN < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = 'https://metacpan.org'
    COLOR = '#0298c3'

    def self.package_link(project, version = nil)
      "https://metacpan.org/release/#{project.name}"
    end

    def self.project_names
      page = 1
      projects = []
      while true
        r = get("https://fastapi.metacpan.org/v1/release/_search?q=status:latest&fields=distribution&sort=date:desc&size=5000&from=#{page*5000}")['hits']['hits']
        break if r == []
        projects += r
        page +=1
      end
      projects.map{|project| project['fields']['distribution'] }.uniq
    end

    def self.recent_names
      names = get('https://fastapi.metacpan.org/v1/release/_search?q=status:latest&fields=distribution&sort=date:desc&size=100')['hits']['hits']
      names.map{|project| project['fields']['distribution'] }.uniq
    end

    def self.project(name)
      get("https://fastapi.metacpan.org/v1/release/#{name}")
    end

    def self.mapping(project)
      {
        :name => project['distribution'],
        :homepage => project.fetch('resources',{})['homepage'],
        :description => project['abstract'],
        :licenses => project.fetch('license', []).join(','),
        :repository_url => repo_fallback(project.fetch('resources',{}).fetch('repository',{})['web'], project.fetch('resources',{})['homepage']),
        :versions => self.versions(project),
      }
    end

    def self.versions(project, name)
      versions = get("https://fastapi.metacpan.org/v1/release/_search?q=distribution:#{project['distribution']}&size=5000&fields=version,date")['hits']['hits']
      versions.map do |version|
        {
          :number => version['fields']['version'],
          :published_at => version['fields']['date']
        }
      end
    end

    def self.dependencies(name, version, project)
      versions = project[:versions]
      version_data = versions.find{|v| v['fields']['version'] == version }
      version_data['fields']['dependency'].select{|dep| dep['relationship'] == 'requires' }.map do |dep|
        {
          project_name: dep['module'].gsub('::', '-'),
          requirements: dep['version'],
          kind: dep['phase'],
          platform: self.name.demodulize
        }
      end
    end
  end
end
