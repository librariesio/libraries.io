module RepositoryIssue
  class Gitlab < Base

    def url
      path = issue.pull_request ? 'merge_requests' : 'issues'
      "#{issue.repository.url}/#{path}/#{issue.number}"
    end

    def self.fetch_issue(repo_full_name, issue_number, token = nil)
      # GitLab have seperate APIs for issues/merge requests but they share the same issue number space
      # so we first check to see if the number corresponds to an issue, otherwise check the merge api
      issue = api_client(token).issues(repo_full_name, iids: issue_number).first
      issue = api_client(token).merge_requests(repo_full_name, iid: issue_number).first if issue.nil?
      issue
    rescue *RepositoryHost::Gitlab::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.create_from_hash(name_with_owner, issue_hash, token = nil)
      issue_hash = issue_hash.to_hash.with_indifferent_access
      repository = Repository.host('GitLab').find_by_full_name(name_with_owner) || RepositoryHost::Gitlab.create(name_with_owner)
      i = repository.issues.find_or_create_by(uuid: issue_hash[:id])
      i.repository_user_id = issue_hash[:author][:id] # problematic
      i.repository_id = repository.id
      i.labels = issue_hash[:labels]
      i.pull_request = issue_hash.keys.include?("merge_status")
      i.comments_count = issue_hash[:user_notes_count]
      i.host_type = 'GitLab'
      i.number = issue_hash[:iid]
      i.state = issue_hash[:state] == 'opened' ? 'open' : 'closed'
      i.body = issue_hash[:description]
      i.locked = false
      i.assign_attributes issue_hash.slice(:title, :created_at, :updated_at)
      if i.changed?
        i.last_synced_at = Time.now
        i.save!
      end
      i
    end

    private

    def self.api_client(token = nil)
      ::Gitlab.client(endpoint: 'https://gitlab.com/api/v3', private_token: token || ENV['GITLAB_KEY'])
    end
  end
end
