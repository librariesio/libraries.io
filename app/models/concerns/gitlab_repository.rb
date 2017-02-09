module GitlabRepository
  extend ActiveSupport::Concern

  included do
    IGNORABLE_GITLAB_EXCEPTIONS = [Gitlab::Error::NotFound]

    def self.create_from_gitlab(full_name, token = nil)
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
      create_from_hash(repo_hash)
    rescue *IGNORABLE_GITLAB_EXCEPTIONS
      nil
    end

    def self.gitlab_client(token = nil)
      Gitlab.client(endpoint: 'https://gitlab.com/api/v3', private_token: token || ENV['GITLAB_KEY'])
    end
  end

  def gitlab_client(token = nil)
    Repository.gitlab_client(token)
  end

  def gitlab_avatar_url(size = 60)
    logo_url
  end
end
