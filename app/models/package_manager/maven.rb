module PackageManager
  class Maven < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    SECURITY_PLANNED = true
    URL = "http://maven.org"
    BASE_URL = "https://maven-repository.com"
    COLOR = '#b07219'
    MAX_DEPTH = 5

    def self.package_link(project, version = nil)
      if version
        "http://search.maven.org/#artifactdetails%7C#{project.name.gsub(':', '%7C')}%7C#{version}%7Cjar"
      else
        group, artifact = project.name.split(':')
        "http://search.maven.org/#search%7Cgav%7C1%7Cg%3A%22#{group}%22%20AND%20a%3A%22#{artifact}%22"
      end
    end

    def self.download_url(name, version = nil)
      maven_name = project_name(name)
      "https://repo1.maven.org/maven2/#{maven_name[:groupId]}/#{maven_name[:artifactId]}/#{version}/#{maven_name[:artifactId]}-#{version}.jar"
    end

    def self.check_status_url(project)
      maven_name = project_name(project.name)
      "https://repo1.maven.org/maven2/#{maven_name[:groupId]}/#{maven_name[:artifactId]}"
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
      h = project_name(name)
      h[:versions] = versions(h)
      h
    end

    def self.mapping(project, depth = 0)
      base_url = "http://repo1.maven.org/maven2/#{project[:groupId]}/#{project[:artifactId]}"
      latest_version = project[:versions].sort_by {|version| Date.parse(version[:published_at])}.reverse.first[:number]
      version_xml = get_xml(base_url + "/#{latest_version}/#{project[:artifactId]}-#{latest_version}.pom")
      self.mapping_from_pom_xml(version_xml, depth).merge({name: project[:name]})
    end

    def self.mapping_from_pom_xml(version_xml, depth = 0)
      if version_xml.respond_to?('project')
        xml = version_xml.project
      else
        xml = version_xml
      end

      parent = {
        description: nil,
        homepage: nil,
        repository_url: "",
        licenses: ""
      }
      if xml.locate('parent').first && depth < MAX_DEPTH
        group_id = xml.locate('parent/groupId').first&.nodes&.first
        artifact_id = xml.locate('parent/artifactId').first&.nodes&.first
        if group_id && artifact_id
          parent = mapping(project([group_id, artifact_id].join(":")), depth += 1)
        end
      end

      # merge with parent data if available and take child values on overlap
      child = {
        description: xml.locate('description').first&.nodes&.first,
        homepage: xml.locate('url').first&.nodes&.first,
        repository_url: repo_fallback(xml.locate('scm/url').first&.nodes&.first,
                                      xml.locate('url').first&.nodes&.first),
        licenses: xml.locate('licenses/license/name').map{|l| l.nodes}.flatten.join(",")
      }.reject{|k,v| v.nil? || v.empty?}
      parent.merge(child)
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

    def self.project_name(name)
      sections = name.split(':')
      {
        name: name,
        path: name.split(':').join('/'),
        groupId: sections[0].gsub('.', '/'),
        artifactId: sections[1]
      }
    end
  end
end
