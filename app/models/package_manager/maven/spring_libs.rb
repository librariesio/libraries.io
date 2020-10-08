# frozen_string_literal: true

class PackageManager::Maven::SpringLibs < PackageManager::Maven
  REPOSITORY_SOURCE_NAME = "SpringLibs"
  HIDDEN = true

  def self.repository_base
    "https://repo.spring.io/libs-release-local"
  end

  def self.project_names
    get("https://maven.libraries.io/springLibsRelease/all")
  end

  def self.recent_names
    get("https://maven.libraries.io/springLibsRelease/all")
  end

  def self.package_link(project, version = nil)
    if version
      MavenUrl.from_name(project.name, repository_base).jar(version)
    else
      MavenUrl.from_name(project.name, repository_base).base
    end
  end

  def self.download_url(name, version = nil)
    if version
      MavenUrl.from_name(name, repository_base).jar(version)
    else
      MavenUrl.from_name(name, repository_base).base
    end
  end

  def self.check_status_url(project)
    MavenUrl.from_name(project.name, repository_base).base
  end

  def self.versions(_project, name)
    versions_page = get_raw(MavenUrl.from_name(name, repository_base).base)
    found_versions = Nokogiri::HTML(versions_page)
      .xpath("//a/@href") # get all links on the page
      .map(&:value) # get the text shown for each link
      .select { |val| val.ends_with? "/" } # select only the directory links
      .map { |link| link.chomp("/") } # remove trailing slash
      .reject { |line| line == ".." } # remove the parent level directory link

    retrieve_versions(found_versions.filter { |item| !item.ends_with?("-SNAPSHOT") }, name)
  end

  def self.db_platform
    "Maven"
  end
end
