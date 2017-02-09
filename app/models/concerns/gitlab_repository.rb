module GitlabRepository
  extend ActiveSupport::Concern

  included do
    IGNORABLE_GITLAB_EXCEPTIONS = [Gitlab::Error::NotFound]

    def self.create_from_gitlab(full_name, token = nil)
      repo_hash = map_from_gitlab(full_name, token)
      create_from_hash(repo_hash)
    rescue *IGNORABLE_GITLAB_EXCEPTIONS
      nil
    end

    def self.gitlab_client(token = nil)
      Gitlab.client(endpoint: 'https://gitlab.com/api/v3', private_token: token || ENV['GITLAB_KEY'])
    end

    def self.map_from_gitlab(full_name, token = nil)
      client = gitlab_client(token)
      project = client.project(full_name.gsub('/','%2F'))
      repo_hash = project.to_hash.with_indifferent_access.slice(:id, :description, :created_at, :name, :open_issues_count, :forks_count, :default_branch)

      repo_hash.merge!({
        host_type: 'GitLab',
        full_name: project.path_with_namespace,
        owner: {},
        fork: !!project.forked_from_project,
        updated_at: project.last_activity_at,
        stargazers_count: project.star_count,
        has_issues: project.issues_enabled,
        has_wiki: project.wiki_enabled,
        scm: 'git',
        private: !project.public,
        pull_requests_enabled: project.merge_requests_enabled,
        logo_url: project.avatar_url
      })
    end
  end

  def gitlab_client(token = nil)
    Repository.gitlab_client(token)
  end

  def gitlab_avatar_url(size = 60)
    logo_url
  end

  def update_from_gitlab(token = nil)
    begin
      r = map_from_gitlab(self.full_name)
      return unless r.present?
      self.uuid = r[:id] unless self.uuid == r[:id]
       if self.full_name.downcase != r[:full_name].downcase
         clash = Repository.where('lower(full_name) = ?', r[:full_name].downcase).first
         if clash && (!clash.update_from_gitlab(token) || clash.status == "Removed")
           clash.destroy
         end
         self.full_name = r[:full_name]
       end
      self.owner_id = r[:owner][:id]
      self.license = Project.format_license(r[:license][:key]) if r[:license]
      self.source_name = r[:parent][:full_name] if r[:fork]
      assign_attributes r.slice(*API_FIELDS)
      save! if self.changed?
    rescue Gitlab::Error::NotFound
      update_attribute(:status, 'Removed') if !self.private?
    rescue *IGNORABLE_GITLAB_EXCEPTIONS
      nil
    end
  end
end
