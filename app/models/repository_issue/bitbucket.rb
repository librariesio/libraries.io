# frozen_string_literal: true
module RepositoryIssue
  class Bitbucket < Base

    def url
      path = issue.pull_request ? 'pull-requests' : 'issues'
      "#{issue.repository.url}/#{path}/#{issue.number}"
    end

    def label_url(label)
      "#{issue.repository.url}/issues?kind=#{ERB::Util.url_encode(label)}"
    end

    def self.fetch_issue(repo_full_name, issue_number, type, token = nil)
      owner, repo_name = repo_full_name.split('/')
      if type == 'issue'
        api_client.issues.get(owner, repo_name, issue_number).to_hash.with_indifferent_access.merge(type: 'issue')
      else
        api_client.pull_requests.get(owner, repo_name, issue_number).to_hash.with_indifferent_access.merge(type: 'pull_request')
      end
    rescue *RepositoryHost::Bitbucket::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.create_from_hash(name_with_owner, issue_hash, token = nil)
      issue_hash = issue_hash.to_hash.with_indifferent_access
      repository = Repository.host('Bitbucket').find_by_full_name(name_with_owner) || RepositoryHost::Bitbucket.create(name_with_owner)
      return if repository.nil?
      if issue_hash[:type] == 'pullrequest'
        issue_hash[:local_id] = issue_hash[:id]
        issue_hash[:content] = issue_hash[:description]
        issue_hash[:status] = issue_hash[:state]
        issue_hash[:utc_created_on] = issue_hash[:created_on]
        issue_hash[:utc_last_updated] = issue_hash[:updated_on]
      end
      uuid = make_uuid(repository.uuid, issue_hash[:type], issue_hash[:local_id])
      i = repository.issues.find_or_create_by(uuid: uuid)

      user = RepositoryUser.where(host_type: 'Bitbucket').find_by_login(issue_hash[:reported_by][:username]) || RepositoryOwner::Bitbucket.download_user_from_host('Bitbucket', issue_hash[:reported_by][:username]) rescue nil
      i.repository_user_id = user.id if user.present?

      i.repository_id = repository.id
      i.labels = [issue_hash.fetch(:metadata, {})[:kind]]
      i.pull_request = issue_hash[:type] == 'pullrequest'
      i.comments_count = issue_hash[:comment_count]
      i.host_type = 'Bitbucket'
      i.number = issue_hash[:local_id]
      i.state = ['open', 'new', 'on hold'].include?(issue_hash[:status].downcase) ? 'open' : 'closed'
      i.body = issue_hash[:content]
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
