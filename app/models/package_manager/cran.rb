# frozen_string_literal: true

module PackageManager
  class CRAN < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://cran.r-project.org/"
    COLOR = "#198CE7"

    def self.package_link(project, _version = nil)
      "https://cran.r-project.org/package=#{project.name}"
    end

    def self.download_url(name, version = nil)
      "https://cran.r-project.org/src/contrib/#{name}_#{version}.tar.gz"
    end

    def self.documentation_url(name, _version = nil)
      "http://cran.r-project.org/web/packages/#{name}/#{name}.pdf"
    end

    def self.check_status_url(project)
      "http://cran.r-project.org/web/packages/#{project.name}/index.html"
    end

    def self.project_names
      html = get_html("https://cran.r-project.org/web/packages/available_packages_by_date.html")
      html.css("tr")[1..-1].map { |tr| tr.css("td")[1].text.strip }
    end

    def self.recent_names
      project_names[0..15].uniq
    end

    def self.project(name)
      html = get_html("https://cran.r-project.org/web/packages/#{name}/index.html")
      info = {}
      table = html.css("table")[0]
      return nil if table.nil?

      table.css("tr").each do |tr|
        tds = tr.css("td").map(&:text)
        info[tds[0]] = tds[1]
      end

      { name: name, html: html, info: info }
    end

    def self.mapping(project)
      {
        name: project[:name],
        homepage: project[:info].fetch("URL:", "").split(",").first,
        description: project[:html].css("h2").text.split(":")[1..-1].join(":").strip,
        licenses: project[:info]["License:"],
        repository_url: repo_fallback("", (project[:info].fetch("URL:", "").split(",").first.presence || project[:info]["BugReports:"])),
      }
    end

    def self.versions(project)
      [{
        number: project[:info]["Version:"],
        published_at: project[:info]["Published:"],
      }] + find_old_versions(project)
    end

    def self.find_old_versions(project)
      archive_page = get_html("https://cran.r-project.org/src/contrib/Archive/#{project[:name]}/")
      trs = archive_page.css("table").css("tr").select do |tr|
        tds = tr.css("td")
        tds[1]&.text&.match(/tar\.gz$/)
      end
      trs.map do |tr|
        tds = tr.css("td")
        {
          number: tds[1].text.strip.split("_").last.gsub(".tar.gz", ""),
          published_at: tds[2].text.strip,
        }
      end
    end

    def self.dependencies(name, version, project)
      find_and_map_dependencies(name, version, project)
    end

    def self.find_dependencies(name, version)
      begin
        url = "https://cran.rstudio.com/src/contrib/#{name}_#{version}.tar.gz"
        head_response = Typhoeus.head(url)
        raise if head_response.code != 200
      rescue StandardError
        url = "https://cran.rstudio.com/src/contrib/Archive/#{name}/#{name}_#{version}.tar.gz"
      end

      folder_name = "#{name}_#{version}"
      tarball_name = "#{folder_name}.tar.gz"
      downloaded_file = File.open "/tmp/#{tarball_name}", "wb"
      request = Typhoeus::Request.new(url)
      request.on_headers do |response|
        return [] if response.code != 200
      end
      request.on_body { |chunk| downloaded_file.write(chunk) }
      request.on_complete { downloaded_file.close }
      request.run

      `mkdir /tmp/#{folder_name} && tar xvzf /tmp/#{tarball_name} -C /tmp/#{folder_name}  --strip-components 1`

      contents = `cat /tmp/#{folder_name}/DESCRIPTION`

      `rm -rf /tmp/#{folder_name} /tmp/#{tarball_name}`

      Bibliothecary.analyse_file("DESCRIPTION", contents).first.fetch(:dependencies)
    ensure
      `rm -rf /tmp/#{folder_name} /tmp/#{tarball_name}`
      []
    end
  end
end
