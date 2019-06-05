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
    LICENSE_STRINGS = {
      "http://www.apache.org/licenses/LICENSE-2.0" => "Apache-2.0",
      "http://www.eclipse.org/legal/epl-v10.html" => "Eclipse Public License (EPL), Version 1.0",
    }

    def self.package_link(project, version = nil)
      MavenUrl.from_name(project.name).search(version)
    end

    def self.download_url(name, version = nil)
      MavenUrl.from_name(name).jar(version)
    end

    def self.check_status_url(project)
      MavenUrl.from_name(project.name).base
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
      {
        name: name,
        path: sections.join('/'),
        groupId: sections[0],
        artifactId: sections[1],
        versions: versions(h),
      }
    end

    def self.mapping(project, depth = 0)
      version_xml = get_pom(project[:groupId], project[:artifactId], latest_version(project))
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
      if xml.locate('parent').present? && depth < MAX_DEPTH
        group_id = xml.locate('parent/groupId/?[0]').first
        artifact_id = xml.locate('parent/artifactId/?[0]').first
        version = xml.locate('parent/version/?[0]').first
        if group_id && artifact_id && version
          parent = mapping_from_pom_xml(
            get_pom(group_id, artifact_id, version),
            depth + 1
          )
        end
      end

      # merge with parent data if available and take child values on overlap
      child = {
        description: xml.locate('description/?[0]').first,
        homepage: xml.locate('url/?[0]').first,
        repository_url: repo_fallback(
          xml.locate('scm/url/?[0]').first,
          xml.locate('url/?[0]').first
        ),
        licenses: licenses(xml).join(","),
      }.select { |k, v| v.present? }

      parent.merge(child)
    end

    def self.dependencies(name, version, project)
      pom_file = get_raw(MavenUrl.from_name(name).pom(version))
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

    def self.get_pom(group_id, artifact_id, version, seen=[])
      xml = get_xml(MavenUrl.new(group_id, artifact_id).pom(version))

      seen << [group_id, artifact_id, version]

      next_group_id = xml.locate('distributionManagement/relocation/groupId/?[0]').first || group_id
      next_artifact_id = xml.locate('distributionManagement/relocation/artifactId/?[0]').first || artifact_id
      next_version = xml.locate('distributionManagement/relocation/version/?[0]').first || version

      if seen.include?([next_group_id, next_artifact_id, next_version])
        xml

      else
        begin
          get_pom(next_group_id, next_artifact_id, next_version, seen)
        rescue Faraday::Error, Ox::Error
          xml
        end
      end
    end

    def self.licenses(xml)
      xml_licenses = xml
        .locate('licenses/license/name')
        .flat_map(&:nodes)
      return xml_licenses if xml_licenses.any?

      comments = xml.locate('*/^Comment')
      LICENSE_STRINGS
        .select { |string, _| comments.any? { |c| c.value.include?(string) } }
        .map(&:last)
    end

    def self.latest_version(project)
      if project[:versions].present?
        project[:versions]
          .max_by { |version| version[:published_at] }
          .dig(:number)
      else
        # TODO this is in place to handle packages that are no longer on maven-repository.com
        # this could be removed if we switched to a package data provider that supplied full information
        Project
          .find_by(name: project[:name], platform: 'Maven')
          &.versions
          &.max_by(&:published_at)
          &.number
      end
    end

    class MavenUrl
      def self.from_name(name)
        new(*name.split(':', 2))
      end

      def initialize(group_id, artifact_id)
        @group_id = group_id
        @artifact_id = artifact_id
      end

      def base
        "https://repo1.maven.org/maven2/#{group_path}/#{@artifact_id}"
      end

      def jar(version)
        base + "/#{version}/#{@artifact_id}-#{version}.jar"
      end

      def pom(version)
        base + "/#{version}/#{@artifact_id}-#{version}.pom"
      end

      def search(version=nil)
        if version
          "http://search.maven.org/#artifactdetails%7C#{@group_id}%7C#{@artifact_id}%7C#{version}%7Cjar"
        else
          "http://search.maven.org/#search%7Cgav%7C1%7Cg%3A%22#{@group_id}%22%20AND%20a%3A%22#{@artifact_id}%22"
        end
      end

      private

      def group_path
        @group_id.gsub('.', '/')
      end
    end
  end
end
