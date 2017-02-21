module RepositoryHost
  class Gitlab < Base
    IGNORABLE_EXCEPTIONS = [::Gitlab::Error::NotFound, ::Gitlab::Error::Forbidden]

    def avatar_url(_size = 60)
      repository.logo_url
    end

    def self.create(full_name, token = nil)
      Repository.create_from_hash(fetch_repo(full_name, token))
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def download_fork_source(token = nil)
      super
      Repository.create_from_gitlab(repository.source_name, token)
    end

    def download_readme(token = nil)
      files = api_client(token).tree(repository.full_name.gsub('/','%2F'))
      paths =  files.map(&:path)
      readme_path = paths.select{|path| path.match(/^readme/i) }.first
      return if readme_path.nil?
      raw_content =  api_client(token).file_contents(repository.full_name.gsub('/','%2F'), readme_path)
      contents = {
        html_body: GitHub::Markup.render(readme_path, raw_content)
      }

      if repository.readme.nil?
        repository.create_readme(contents)
      else
        repository.readme.update_attributes(contents)
      end
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def download_tags(token = nil)
      remote_tags = api_client(token).tags(repository.full_name.gsub('/','%2F')).auto_paginate
      existing_tag_names = repository.tags.pluck(:name)
      remote_tags.each do |tag|
        next if existing_tag_names.include?(tag.name)
        repository.tags.create({
          name: tag.name,
          kind: "tag",
          sha: tag.commit.id,
          published_at: tag.commit.committed_date
        })
      end
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def update(token = nil)
      begin
        r = self.class.fetch_repo(repository.full_name)
        return unless r.present?
        repository.uuid = r[:id] unless repository.uuid == r[:id]
         if repository.full_name.downcase != r[:full_name].downcase
           clash = Repository.host('GitLab').where('lower(full_name) = ?', r[:full_name].downcase).first
           if clash && (!clash.update_from_repository(token) || clash.status == "Removed")
             clash.destroy
           end
           repository.full_name = r[:full_name]
         end
        repository.owner_id = r[:owner][:id]
        repository.license = Project.format_license(r[:license][:key]) if r[:license]
        repository.source_name = r[:parent][:full_name] if r[:fork]
        repository.assign_attributes r.slice(*Repository::API_FIELDS)
        repository.save! if self.changed?
      rescue ::Gitlab::Error::NotFound
        repository.update_attribute(:status, 'Removed') if !repository.private?
      rescue *IGNORABLE_EXCEPTIONS
        nil
      end
    end

    private

    def self.api_client(token = nil)
      ::Gitlab.client(endpoint: 'https://gitlab.com/api/v3', private_token: token || ENV['GITLAB_KEY'])
    end

    def api_client(token = nil)
      self.class.api_client
    end

    def self.fetch_repo(full_name, token = nil)
      client = api_client(token)
      project = client.project(full_name.gsub('/','%2F'))
      repo_hash = project.to_hash.with_indifferent_access.slice(:id, :description, :created_at, :name, :open_issues_count, :forks_count, :default_branch)

      repo_hash.merge!({
        host_type: 'GitLab',
        full_name: project.path_with_namespace,
        owner: {},
        fork: project.forked_from_project.present?,
        updated_at: project.last_activity_at,
        stargazers_count: project.star_count,
        has_issues: project.issues_enabled,
        has_wiki: project.wiki_enabled,
        scm: 'git',
        private: !project.public,
        pull_requests_enabled: project.merge_requests_enabled,
        logo_url: project.avatar_url,
        parent: {
          full_name: project.forked_from_project.try(:path_with_namespace)
        }
      })
    end
  end
end
