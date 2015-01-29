class Repositories
  class Maven < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    URL = 'http://search.maven.org/'

    def self.load_names
      num = REDIS.get('maven-page').to_i
      if num.nil?
        REDIS.set 'maven-page', 41753
        num = 41753
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

    def self.project(name)
      # maven-scraper
      # https://maven-repository.com/artifact/org.jenkins-ci.plugins/accurev/0.6.30
    end

    def self.mapping(project)
      #   name
      #   keywords
      #   description
      #   licenses
      #   homepage
      #   repository_url
    end

    def self.versions(project)

    end
  end
end
