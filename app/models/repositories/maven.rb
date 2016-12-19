module Repositories
  class Maven < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = false
    LIBRARIAN_SUPPORT = true
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
        page = Repositories::Maven.get_html "https://maven-repository.com/artifact/latest?page=#{number}"
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
      page = Repositories::Maven.get_html "https://maven-repository.com/artifact/latest?page=1"
      page.css('tr')[1..-1].map do |tr|
        tr.css('td')[0..1].map(&:text).join(':')
      end.uniq
    end

    def self.project(name)
      h = {
        name: name,
        path: name.split(':').join('/')
      }
      h[:versions] = versions(h)
      h
    end

    def self.mapping(project)
      latest_version = get_html("https://maven-repository.com/artifact/#{project[:path]}/#{project[:versions][0][:number]}")
      hash = {}
      latest_version.css('tr').each do |tr|
        tds = tr.css('td')
        hash[tds[0].text.gsub(/[^a-zA-Z0-9\s]/,'')] = tds[1] if tds.length == 2
      end
      {
        name: project[:name],
        description: hash['Description'].try(:text),
        homepage: hash['URL'].try(:css,'a').try(:text),
        repository_url: repo_fallback(hash['Connection'].try(:text), hash['URL'].try(:css,'a').try(:text)),
        licenses: hash['Name'].try(:text)
      }
    end

    def self.versions(project)
      # multiple verion pages
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
