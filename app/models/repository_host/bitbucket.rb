module RepositoryHost
  class Bitbucket < Base
    IGNORABLE_EXCEPTIONS = [
      BitBucket::Error::NotFound,
      BitBucket::Error::Forbidden,
      BitBucket::Error::ServiceError,
      BitBucket::Error::InternalServerError,
      BitBucket::Error::ServiceUnavailable,
      BitBucket::Error::Unauthorized]

    def self.api_missing_error_class
      BitBucket::Error::NotFound
    end

    def avatar_url(size = 60)
      "https://bitbucket.org/#{repository.full_name}/avatar/#{size}"
    end

    def domain
      'https://bitbucket.org'
    end

    def blob_url(sha = nil)
      sha ||= repository.default_branch
      "#{url}/src/#{URI.escape(sha)}/"
    end

    def commits_url(author = nil)
      "#{url}/commits"
    end

    def compare_url(branch_one, branch_two)
      "#{url}/compare/#{branch_two}..#{branch_one}#diff"
    end

    def get_file_list(token = nil)
      api_client(token).get_request("1.0/repositories/#{repository.full_name}/directory/")[:values]
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def get_file_contents(path, token = nil)
      file = api_client(token).repos.sources.list(repository.owner_name, repository.project_name, URI.escape(repository.default_branch), URI.escape(path))
      {
        sha: file.node,
        content: file.data
      }
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def download_contributions(token = nil)
      # not implemented yet
    end

    def retrieve_commits(token = nil)
      api_client(token).repos.commits.list(repository.owner_name, repository.project_name)['values']
    end

    def download_forks(token = nil)
      # not implemented yet
    end

    def download_owner
      return if repository.owner && repository.repository_user_id && repository.owner.login == repository.owner_name
      o = RepositoryOwner::Bitbucket.fetch_user(repository.owner_name)
      if o.type == "team"
        org = RepositoryOrganisation.create_from_host('Bitbucket', o)
        if org
          repository.repository_organisation_id = org.id
          repository.repository_user_id = nil
          repository.save
        end
      else
        u = RepositoryUser.create_from_host('Bitbucket', o)
        if u
          repository.repository_user_id = u.id
          repository.repository_organisation_id = nil
          repository.save
        end
      end
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def create_webhook(token = nil)
      # not implemented yet
    end

    def download_readme(token = nil)
      files = api_client(token).repos.sources.list(repository.owner_name, repository.project_name, URI.escape(repository.default_branch || 'master'), '/')
      paths =  files.files.map(&:path)
      readme_path = paths.select{|path| path.match(/^readme/i) }.sort{|path| Readme.supported_format?(path) ? 0 : 1 }.first
      return if readme_path.nil?
      file = get_file_contents(readme_path, token)
      return unless file.present?
      content = Readme.format_markup(readme_path, file[:content])
      return unless content.present?

      if repository.readme.nil?
        repository.create_readme(html_body: content)
      else
        repository.readme.update_attributes(html_body: content)
      end
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def download_tags(token = nil)
      remote_tags = api_client(token).repos.tags(repository.owner_name, repository.project_name)
      existing_tag_names = repository.tags.pluck(:name)
      remote_tags.each do |name, data|
        next if existing_tag_names.include?(name)
        repository.tags.create({
          name: name,
          kind: "tag",
          sha: data.raw_node,
          published_at: data.utctimestamp
        })
      end
      repository.projects.find_each(&:forced_save) if remote_tags.present?
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def self.recursive_bitbucket_repos(url, limit = 5)
      return if limit.zero?
      r = Typhoeus::Request.new(url,
        method: :get,
        headers: { 'Accept' => 'application/json' }).run

      json = Oj.load(r.body)

      json['values'].each do |repo|
        CreateRepositoryWorker.perform_async('Bitbucket', repo['full_name'])
      end

      if json['values'].any? && json['next']
        limit = limit - 1
        REDIS.set 'bitbucket-after', Addressable::URI.parse(json['next']).query_values['after']
        recursive_bitbucket_repos(json['next'], limit)
      end
    end

    def gather_maintenance_stats
      if repository.host_type != "Bitbucket" || repository.projects.any? { |project| project.bitbucket_name_with_owner.blank? }
        repository.repository_maintenance_stats.destroy_all
        return []
      end

      metrics = []

      metrics << MaintenanceStats::Stats::Bitbucket::CommitsStat.new(repository.retrieve_commits).get_stats

      metrics << MaintenanceStats::Stats::Bitbucket::IssueRates.new(repository.issues).get_stats

      add_metrics_to_repo(metrics)
      metrics
    end

    private

    def self.api_client(token = nil)
      BitBucket.new oauth_token: token || ENV['BITBUCKET_KEY']
    end

    def api_client(token = nil)
      self.class.api_client(token)
    end

    def self.fetch_repo(full_name, token = nil)
      client = api_client(token)
      user_name, repo_name = full_name.split('/')
      project = client.repos.get(user_name, repo_name)
      v1_project = client.repos.get(user_name, repo_name, api_version: '1.0')
      repo_hash = project.to_hash.with_indifferent_access.slice(:description, :language, :full_name, :name, :has_wiki, :has_issues, :scm)

      repo_hash.merge!({
        id: project.uuid,
        host_type: 'Bitbucket',
        owner: {},
        homepage: project.website,
        fork: project.parent.present?,
        created_at: project.created_on,
        updated_at: project.updated_on,
        subscribers_count: v1_project.followers_count,
        forks_count: v1_project.forks_count,
        default_branch: project.fetch('mainbranch', {}).try(:fetch, 'name', nil),
        private: project.is_private,
        size: project[:size].to_f/1000,
        parent: {
          full_name: project.fetch('parent', {}).fetch('full_name', nil)
        }
      })
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end
  end
end
