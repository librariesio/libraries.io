module RepositoryIssue
  class Github < Base

    def url
      path = issue.pull_request ? 'pull' : 'issues'
      "#{issue.repository.url}/#{path}/#{issue.number}"
    end

    def self.fetch_issue(repo_full_name, issue_number, token = nil)
      api_client(token).issue(repo_full_name, issue_number)
    rescue *RepositoryHost::Github::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.create_from_hash(name_with_owner, issue_hash, token = nil)
      issue_hash = issue_hash.to_hash
      repository = Repository.host('GitHub').find_by_full_name(name_with_owner) || RepositoryHost::Github.create(name_with_owner)
      i = repository.issues.find_or_create_by(uuid: issue_hash[:id])
      i.repository_user_id = issue_hash[:user][:id]
      i.repository_id = repository.id
      i.labels = issue_hash[:labels].map{|l| l[:name] }
      i.pull_request = issue_hash[:pull_request].present?
      i.comments_count = issue_hash[:comments]
      i.host_type = 'GitHub'
      i.assign_attributes issue_hash.slice(:number, :state, :title, :body, :locked, :closed_at, :created_at, :updated_at)
      if i.changed?
        i.last_synced_at = Time.now
        i.save!
      end
      i
    end

    private

    def self.api_client(token = nil)
      AuthToken.fallback_client(token)
    end
  end
end
