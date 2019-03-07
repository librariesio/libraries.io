module PackageManager
  class Maven < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = "http://maven.org"
    BASE_URL = "https://maven-repository.com"
    COLOR = '#b07219'

    def self.package_link(project, version = nil)
      if version
        "http://search.maven.org/#artifactdetails%7C#{project.name.gsub(':', '%7C')}%7C#{version}%7Cjar"
      else
        group, artifact = project.name.split(':')
        "http://search.maven.org/#search%7Cgav%7C1%7Cg%3A%22#{group}%22%20AND%20a%3A%22#{artifact}%22"
      end
    end

    def self.download_url(name, version = nil)
      _group, artifact = name.split(":")
      "https://repo1.maven.org/maven2/#{name.gsub(/\:|\./, '/')}/#{version}/#{artifact}-#{version}.jar"
    end

    def self.check_status_url(project)
      "https://repo1.maven.org/maven2/#{project.name.gsub(/\:|\./, '/')}/"
    end

    def self.load_names(limit = nil)
      num = REDIS.get('maven-page')
      if limit
        REDIS.set 'maven-page', limit
        num = limit
      elsif num.nil?
        REDIS.set 'maven-page', 41753
        num = 41753
      else
        num = num.to_i
      end

      (1..num).to_a.reverse.each do |number|
        page = get_html "https://maven-repository.com/artifact/latest?page=#{number}"
        page.css('tr')[1..-1].each do |tr|
          REDIS.sadd 'maven-names', tr.css('td')[0..1].map(&:text).join(':')
        end
        REDIS.set 'maven-page', number
      end
    end

    def self.project_names
      REDIS.smembers 'maven-names'
    end

    def self.recent_names
      page = get_html "https://maven-repository.com/artifact/latest?page=1"
      page.css('tr')[1..-1].map do |tr|
        tr.css('td')[0..1].map(&:text).join(':')
      end.uniq
    end

    def self.project(name)
      sections = name.split(':')
      h = {
        name: name,
        path: name.split(':').join('/'),
        groupId: sections[0].gsub('.', '/'),
        artifactId: sections[1]
      }
      h[:versions] = versions(h)
      h
    end

    def self.mapping(project)
      base_url = "http://repo1.maven.org/maven2/#{project[:groupId]}/#{project[:artifactId]}"
      latest_version = project[:versions].sort_by {|version| Date.parse(version[:published_at])}.reverse.first[:number]
      version_xml = get_xml(base_url + "/#{latest_version}/#{project[:artifactId]}-#{latest_version}.pom")
      self.mapping_from_pom_xml(version_xml).merge({name: project[:name]})
    end

    def self.mapping_from_pom_xml(version_xml)
      if version_xml.respond_to?('project')
        xml = version_xml.project
      else
        xml = version_xml
      end
      {
        description: xml.locate('description').first.try(:nodes).try(:first),
        homepage: xml.locate('url').first.try(:nodes).try(:first),
        repository_url: repo_fallback(xml.locate('scm/url').first.try(:nodes).try(:first),
                                      xml.locate('url').first.try(:nodes).try(:first)),
        licenses: xml.locate('licenses/license/name').map{|l| l.nodes}.flatten.join(",")
      }
    end

    def self.dependencies(name, version, project)
      sections = project[:name].split(':')
      groupId = sections[0].gsub('.', '/')
      artifactId = sections[1]
      base_url = "http://repo1.maven.org/maven2/#{groupId}/#{artifactId}"
      pom_file = get_raw(base_url + "/#{version}/#{artifactId}-#{version}.pom")
      Bibliothecary::Parsers::Maven.parse_pom_manifest(pom_file).map do |dep|
        {
          project_name: dep[:name],
          requirements: dep[:requirement],
          kind: dep[:type],
          platform: 'Maven'
        }
      end
    end

    def self.versions(project)
      # multiple version pages
      initial_page = get_html("https://maven-repository.com/artifact/#{project[:path]}/")
      version_pages(initial_page).reduce(extract_versions(initial_page)) do |acc, page|
        acc.concat( extract_versions(get_html(page)) )
      end
    end

    def self.extract_versions(page)
      page.css('tr')[1..-1].map do |tr|
        tds = tr.css('td')
        {
          :number => tds[0].text,
          :published_at => tds[2].text
        }
      end
    end

    def self.version_pages(page)
      page.css('.pagination li a').map{|link| BASE_URL + link['href'] }.uniq
    end
  end
end
