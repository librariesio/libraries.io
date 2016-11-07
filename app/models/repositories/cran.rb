module Repositories
  class CRAN < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    LIBRARIAN_SUPPORT = true
    URL = 'https://cran.r-project.org/'
    COLOR = '#198ce7'

    def self.project_names
      html = get_html("https://cran.r-project.org/web/packages/available_packages_by_date.html")
      html.css('tr')[1..-1].map{|tr| tr.css('td')[1].text.strip}
    end

    def self.recent_names
      project_names[0..30]
    end

    def self.project(name)
      html = get_html("https://cran.r-project.org/web/packages/#{name}/index.html")
      info = {}
      table = html.css('table')[0]
      table.css('tr').each do |tr|
        tds = tr.css('td').map(&:text)
        info[tds[0]] = tds[1]
      end

      {name: name, html: html, info: info}
    end

    def self.mapping(project)
      {
        :name => project[:name],
        :homepage => project[:info].fetch('URL:', '').split(',').first,
        :description => project[:html].css('h2').text.split(':')[1..-1].join(':').strip,
        :licenses => project[:info]['License:'],
        :repository_url => repo_fallback('', (project[:info].fetch('URL:', '').split(',').first.presence || project[:info]['BugReports:']))
      }
    end

    def self.versions(project)
      [{
        :number => project[:info]['Version:'],
        :published_at => project[:info]['Published:']
      }]
    end
  end
end
