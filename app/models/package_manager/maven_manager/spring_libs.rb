module MavenManager
  class SpringLibs < PackageManager::Maven
    REPOSITORY_SOURCE_NAME = 'SpringLibs'

    def self.repository_base
      "https://repo.spring.io/libs-release-local"
    end

    def self.project_names
      get("http://localhost:8080/springLibReleases/all")
    end

    def self.recent_names
      get("http://localhost:8080/springLibReleases/recent")
    end

    def self.load_names(limit = nil)
      project_names.each { |name| REDIS.sadd("maven-spring-lib-names", name)}
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
      link_regex = /([\w\-.]+)\/<\/a>/
      found_versions = versions_page
        .split("\n")
        .filter {|line| line.include?("href") && line.match?(link_regex)}
        .map{|line| line.match(link_regex)[1]}
        .reject{|line| line == ".."}

      retrieve_versions(found_versions.filter {|item| !item.ends_with?("-SNAPSHOT")}, name)
    end

    def self.formatted_name
      PackageManager::Maven.formatted_name
    end

    def self.name
      PackageManager::Maven.name
    end
  end
end