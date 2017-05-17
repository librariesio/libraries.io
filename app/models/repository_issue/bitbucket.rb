module RepositoryIssue
  class Bitbucket < Base

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
      BitBucket.new oauth_token: token || ENV['BITBUCKET_KEY']
    end
  end
end
