module RepositoryIssue
  class Gitlab < Base

    def url
      # TODO
    end

    def self.fetch_issue(repo_full_name, issue_number, token = nil)
      # TODO
    end

    def self.create_from_hash(name_with_owner, issue_hash, token = nil)
      # TODO
    end

    private

    def self.api_client(token = nil)
      ::Gitlab.client(endpoint: 'https://gitlab.com/api/v3', private_token: token || ENV['GITLAB_KEY'])
    end
  end
end
