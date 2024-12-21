# frozen_string_literal: true

module PackageManager
  class Maven < MultipleSourcesBase
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    REPOSITORY_SOURCE_NAME = "Maven"
    URL = "http://maven.org"
    COLOR = "#b07219"
    MAX_DEPTH = 50
    LICENSE_STRINGS = {
      "://www.apache.org/licenses/LICENSE-2.0" => "Apache-2.0",
      "://www.eclipse.org/legal/epl-v10" => "Eclipse Public License (EPL), Version 1.0",
      "://www.eclipse.org/legal/epl-2.0" => "Eclipse Public License (EPL), Version 2.0",
      "://www.eclipse.org/org/documents/edl-v10" => "Eclipse Distribution License (EDL), Version 1.0",
    }.freeze
    NAME_DELIMITER = ":"

    PROVIDER_MAP = ProviderMap.new(prioritized_provider_infos: [
      ProviderInfo.new(identifier: "Maven", default: true, provider_class: MavenCentral),
      ProviderInfo.new(identifier: "Google", provider_class: Google),
      ProviderInfo.new(identifier: "Atlassian", provider_class: Atlassian),
      ProviderInfo.new(identifier: "Hortonworks", provider_class: Hortonworks),
      ProviderInfo.new(identifier: "SpringLibs", provider_class: SpringLibs),
      ProviderInfo.new(identifier: "Jboss", provider_class: Jboss),
      ProviderInfo.new(identifier: "JbossEa", provider_class: JbossEa),
    ])

    class POMNotFound < StandardError
      attr_reader :url

      def initialize(url)
        @url = url
        super("Missing POM: #{@url}")
      end
    end

    class POMParseError < StandardError
      attr_reader :url

      def initialize(url)
        @url = url
        super("Unable to parse POM: #{@url}")
      end
    end

    def self.repository_base
      PROVIDER_MAP.default_provider.provider_class.repository_base
    end

    def self.project_names
      # NB this is just the most recent set of incremental updates to maven central, not all releases
      get("https://maven.libraries.io/mavenCentral/recent")
    end

    def self.project(name, latest: nil)
      sections = name.split(NAME_DELIMITER)
      path = sections.join("/")

      latest = latest_version(name) unless latest.present?

      # MavenCentral, at least, can return interpolation strings in maven-metadata.xml,
      # which is not useful to us. In that case, try scraping as a method of finding latest version.
      if latest =~ /\$\{/
        latest = latest_version_scraped(name)
      end
      # latest isn't guaranteed to be in maven metadata so let's just guess if it's not present
      if latest.nil?
        latest = latest_version_scraped(name)
      end

      return {} unless latest.present?

      {
        name: name,
        path: path,
        group_id: sections[0],
        artifact_id: sections[1],
        latest_version: latest,
      }
    rescue StandardError
      {}
    end

    def self.mapping(raw_project)
      begin
        pom_documents = get_pom_documents(raw_project[:group_id], raw_project[:artifact_id], raw_project[:latest_version])
      rescue POMNotFound => e
        Rails.logger.info "Missing POM for #{raw_project[:name]}/#{raw_project[:latest_version]}, trying to scrape latest"
        scraped = latest_version_scraped(raw_project[:name])
        if scraped != raw_project[:latest_version]
          raw_project[:latest_version] = scraped
          return mapping(raw_project)
        end
        raise e
      end

      pom_data = mapping_from_pom_documents(pom_documents)

      MappingBuilder.build_hash(
        name: raw_project[:name],
        description: pom_data[:description],
        homepage: pom_data[:homepage],
        repository_url: pom_data[:repository_url],
        licenses: pom_data[:licenses],
        properties: pom_data[:properties]
      )
    rescue POMNotFound => e
      Rails.logger.info "Missing POM: #{e.url}"
      nil
    end

    def self.get_pom_documents(group_id, artifact_id, version, depth = 0)
      return [] if depth >= MAX_DEPTH

      pom_document = get_pom(group_id, artifact_id, version)
      if pom_document.respond_to?("project")
        pom_document = pom_document.project
      end

      result = [pom_document]

      # Check if the POM document has a parent
      if pom_document.locate("parent").present?
        parent_group_id = extract_pom_value(pom_document, "parent/groupId")&.strip
        parent_artifact_id = extract_pom_value(pom_document, "parent/artifactId")&.strip
        parent_version = extract_pom_value(pom_document, "parent/version")&.strip
        if parent_group_id && parent_artifact_id && parent_version
          # Recursively call this method for the parent POM document. Parents
          # are added to the end of the array
          result += get_pom_documents(parent_group_id, parent_artifact_id, parent_version, depth + 1)
        end
      end

      result
    end

    def self.mapping_from_pom_documents(pom_documents)
      properties = {}

      pom_documents.each do |pom_document|
        # prefer child values on overlap
        new_properties = extract_pom_properties(pom_document)
        properties = new_properties.merge(properties)
      end

      result = {
        properties: properties,
      }

      # Process all POM files to merge the data. Take child values on overlap
      pom_documents.each do |pom_document|
        new_result = {
          description: extract_pom_value(pom_document, "description", properties),
          homepage: extract_pom_value(pom_document, "url", properties)&.strip,
          repository_url: repo_fallback(
            extract_pom_value(pom_document, "scm/url", properties)&.strip,
            extract_pom_value(pom_document, "url", properties)&.strip
          ),
          licenses: licenses(pom_document).join(","),
        }.select { |_k, v| v.present? }

        result = new_result.merge(result)
      end

      result
    end

    def self.extract_pom_value(xml, location, parent_properties = {})
      # Bibliothecary will help handle property expansion within the xml
      Bibliothecary::Parsers::Maven.extract_pom_info(xml, location, parent_properties)
    end

    def self.extract_pom_properties(xml)
      properties = xml.locate("properties/*").each_with_object({}) do |prop_node, all|
        all[prop_node.value] = prop_node.nodes.first if prop_node.respond_to?(:nodes)
      end

      # <scm><url /></scm> can be found outside of <properties /> but we're only
      # passing <properties /> to extract_pom_info() for now, even though most
      # elements in a parent pom are inheritable (except for artifactId, name,
      # and prerequisites) (see https://maven.apache.org/pom.html#inheritance)
      # To ensure that the correct "scm.url" can be inherited from parent poms,
      # we manually set "scm.url" - if it exists in the parent pom - as a
      # property for child poms to use during interpolation.
      if properties["scm.url"].blank? && (node = xml.locate("scm/url").first) && node.respond_to?(:nodes)
        properties["scm.url"] = node.nodes.first
      end

      properties
    end

    def self.parse_pom_manifest(name, version)
      group_id, artifact_id = *MavenUrl.parse_name(name)
      pom_documents = get_pom_documents(group_id, artifact_id, version)
      mapping = mapping_from_pom_documents(pom_documents)

      Bibliothecary::Parsers::Maven.parse_pom_manifests(pom_documents.map { |doc| Ox.dump(doc) }, mapping[:properties])
    end

    def self.dependencies(name, version, _project)
      parse_pom_manifest(name, version).map do |dep|
        {
          project_name: dep[:name],
          requirements: dep[:requirement],
          kind: dep[:type],
          optional: dep.optional.blank? ? false : dep.optional,
          platform: db_platform,
        }
      end
    end

    def self.versions(raw_project, name)
      if raw_project && raw_project[:versions]
        raw_project[:versions].map do |v|
          VersionBuilder.build_hash(v)
        end
      else
        xml_metadata = maven_metadata(name)
        xml_versions = Nokogiri::XML(xml_metadata).css("version").map(&:text)
        retrieve_versions(xml_versions.filter { |item| !item.ends_with?("-SNAPSHOT") }, name)
      end
    end

    def self.one_version(raw_project, sync_version)
      name = raw_project[:name]

      pom = get_pom(*name.split(NAME_DELIMITER, 2), sync_version)
      begin
        license_list = licenses(pom)
      rescue StandardError
        license_list = nil
      end

      if license_list.blank? && pom.respond_to?("project") && pom.project.locate("parent").present?
        parent_version = extract_pom_value(pom.project, "parent/version")&.strip
        Rails.logger.info("[POM has parent no license] name=#{name} parent_version=#{parent_version} child_version=#{sync_version}")
      end

      VersionBuilder.build_hash(
        number: sync_version,
        published_at: Time.parse(pom.locate("publishedAt").first.text),
        original_license: license_list
      )
    end

    def self.retrieve_versions(versions, name)
      # TODO: This should also look for the parent POM and if it exists + the child POM
      # is missing license data, use the data from the parent POM
      versions
        .map do |version|
          one_version({ name: name }, version)
        rescue Ox::Error, POMNotFound
          StructuredLog.capture("MAVEN_RETRIEVE_VERSION_FAILURE", { version: version, name: name, message: "Version POM not found or valid" })
          next
        end
        .compact
    end

    def self.download_pom(group_id, artifact_id, version)
      url = MavenUrl.new(group_id, artifact_id, repository_base).pom(version)
      pom_request = request(url)
      raise POMNotFound, url if pom_request.status == 404

      xml = Ox.parse(pom_request.body)
      raise POMParseError, url if xml.nil?

      published_at = pom_request.headers["Last-Modified"]
      pat = Ox::Element.new("publishedAt")
      pat << published_at
      xml << pat
      xml
    end

    def self.get_pom(group_id, artifact_id, version, seen = [])
      xml = download_pom(group_id, artifact_id, version)
      seen << [group_id, artifact_id, version]

      next_group_id = xml.locate("distributionManagement/relocation/groupId/?[0]").first || group_id
      next_artifact_id = xml.locate("distributionManagement/relocation/artifactId/?[0]").first || artifact_id
      next_version = xml.locate("distributionManagement/relocation/version/?[0]").first || version

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
        .locate("*/licenses/license/name")
        .flat_map(&:nodes)
      return xml_licenses if xml_licenses.any?

      comments = xml.locate("*/^Comment")
      LICENSE_STRINGS
        .select { |string, _| comments.any? { |c| c.value.include?(string) } }
        .map(&:last)
    end

    def self.maven_metadata(name)
      get_raw(MavenUrl.from_name(name, repository_base, NAME_DELIMITER).maven_metadata)
    end

    def self.latest_version(name)
      xml_metadata = maven_metadata(name)
      Nokogiri::XML(xml_metadata)
        .css("versioning > latest, versioning > release, metadata > version")
        .map(&:text)
        .first
    end

    # Override this to add HTML-scraping logic to fetch latest_version.
    def self.latest_version_scraped(_name)
      nil
    end

    def self.db_platform
      "Maven"
    end
  end
end
