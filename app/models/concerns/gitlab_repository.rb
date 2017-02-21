module GitlabRepository
  extend ActiveSupport::Concern

  included do
    IGNORABLE_GITLAB_EXCEPTIONS = [Gitlab::Error::NotFound, Gitlab::Error::Forbidden]

    def self.gitlab_client(token = nil)
      Gitlab.client(endpoint: 'https://gitlab.com/api/v3', private_token: token || ENV['GITLAB_KEY'])
    end

    def self.recursive_gitlab_repos(page_number = 1, limit = 10)
      r = Typhoeus.get("https://gitlab.com/explore/projects?&page=#{page_number}&sort=created_asc")
      if r.code == 500
        recursive_gitlab_repos(page_number.to_i + 1, limit)
      else
        page = Nokogiri::HTML(r.body)
        names = page.css('a.project').map{|project| project.attributes["href"].value[1..-1] }
        names.each do |name|
          CreateRepositoryWorker.perform_async('GitLab', name)
        end
      end
      if names.any?
        limit = limit - 1
        REDIS.set 'gitlab-page', page_number
        recursive_gitlab_repos(page_number.to_i + 1, limit)
      end
    end
  end

  def gitlab_client(token = nil)
    Repository.gitlab_client(token)
  end
end
