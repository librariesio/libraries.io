module RepositoryIssue
  class Bitbucket < Base

    def url
      path = issue.pull_request ? 'pull-requests' : 'issues'
      "#{issue.repository.url}/#{path}/#{issue.number}"
    end

    def label_url(label)
      "#{issue.repository.url}/issues?kind=#{ERB::Util.url_encode(label)}"
    end

    def self.fetch_issue(repo_full_name, issue_number, token = nil)
      owner, repo_name = repo_full_name.split('/')
      api_client.issues.get(owner, repo_name, issue_number).to_hash.with_indifferent_access.merge(type: 'issue')
    rescue *RepositoryHost::Bitbucket::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.create_from_hash(name_with_owner, issue_hash, token = nil)
      issue_hash = issue_hash.to_hash.with_indifferent_access
      repository = Repository.host('Bitbucket').find_by_full_name(name_with_owner) || RepositoryHost::Bitbucket.create(name_with_owner)
      uuid = make_uuid(repository.uuid, issue_hash[:type], issue_hash[:id])
      i = repository.issues.find_or_create_by(uuid: issue_hash[:id])
      #i.repository_user_id = issue_hash[:reporter][:uuid] # problematic
      i.repository_id = repository.id
      i.labels = [issue_hash[:metadata][:kind], issue_hash[:metadata][:component], issue_hash[:metadata][:milestone]].reject(&:empty?)
      i.pull_request = issue_hash[:type] == 'pull_request'
      i.comments_count = issue_hash[:comment_count]
      i.host_type = 'Bitbucket'
      i.number = issue_hash[:local_id]
      i.state = issue_hash[:state] == 'opened' ? 'open' : 'closed'
      i.body = issue_hash[:description]
      i.locked = false
      i.created_at = issue_hash[:utc_created_on]
      i.updated_at = issue_hash[:utc_last_updated]
      i.assign_attributes issue_hash.slice(:title)
      if i.changed?
        i.last_synced_at = Time.now
        i.save!
      end
      i
    end

    def self.make_uuid(repository_uuid, type, id)
      "#{repository_uuid}-#{type}-#{id}"
    end

    private

    def self.api_client(token = nil)
      BitBucket.new oauth_token: token || ENV['BITBUCKET_KEY']
    end
  end
end
