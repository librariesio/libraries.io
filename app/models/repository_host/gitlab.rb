module RepositoryHost
  class Gitlab < Base
    IGNORABLE_EXCEPTIONS = [::Gitlab::Error::NotFound,
                            ::Gitlab::Error::Forbidden,
                            ::Gitlab::Error::Unauthorized,
                            ::Gitlab::Error::InternalServerError,
                            ::Gitlab::Error::Parsing]

    def self.api_missing_error_class
      ::Gitlab::Error::NotFound
    end

    def avatar_url(_size = 60)
      repository.logo_url
    end

    def domain
      'https://gitlab.com'
    end

    def forks_url
      "#{url}/forks"
    end

    def contributors_url
      "#{url}/graphs/#{repository.default_branch}"
    end

    def blob_url(sha = nil)
      sha ||= repository.default_branch
      "#{url}/blob/#{sha}/"
    end

    def commits_url(author = nil)
      "#{url}/commits/#{repository.default_branch}"
    end

    def download_contributions(token = nil)
      # not implemented yet
    end

    def download_forks(token = nil)
      # not implemented yet
    end

    def retrieve_commits
      # not implemented yet
    end

    def download_owner
      return if repository.owner && repository.repository_user_id && repository.owner.login == repository.owner_name
      namespace = api_client.project(repository.full_name).try(:namespace)
      return unless namespace
      if namespace.kind == 'group'
        o = RepositoryOwner::Gitlab.api_client.group(namespace.path)
        org = RepositoryOrganisation.create_from_host('GitLab', o)
        if org
          repository.repository_organisation_id = org.id
          repository.repository_user_id = nil
          repository.save
        end
      elsif namespace.kind == 'user'
        o = RepositoryOwner::Gitlab.fetch_user(namespace.path)
        u = RepositoryUser.create_from_host('GitLab', o)
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

    def get_file_list(token = nil)
      tree = api_client(token).tree(repository.full_name, recursive: true)
      tree.select{|item| item.type == 'blob' }.map{|file| file.path }
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def get_file_contents(path, token = nil)
      file = api_client(token).get_file(repository.full_name, path, repository.default_branch)
      {
        sha: file.commit_id,
        content: Base64.decode64(file.content)
      }
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def download_readme(token = nil)
      files = api_client(token).tree(repository.full_name)
      paths =  files.map(&:path)
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
      existing_tag_names = repository.tags.pluck(:name)
      remote_tags = api_client(token).tags(repository.full_name).auto_paginate do |tag|
        next if existing_tag_names.include?(tag.name)
        next if tag.commit.nil?
        repository.tags.create({
          name: tag.name,
          kind: "tag",
          sha: tag.commit.id,
          published_at: tag.commit.committed_date
        })
      end
      repository.projects.find_each(&:forced_save) if remote_tags.present?
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def self.recursive_gitlab_repos(page_number = 1, limit = 5, order = "created_asc")
      return if limit.zero?
      r = Typhoeus.get("https://gitlab.com/explore/projects?&page=#{page_number}&sort=#{order}")
      if r.code == 500
        recursive_gitlab_repos(page_number.to_i + 1, limit, order)
      else
        page = Nokogiri::HTML(r.body)
        names = page.css('a.project').map{|project| project.attributes["href"].value[1..-1] }
        names.each do |name|
          if r = Repository.host('GitLab').find_by_full_name(name)
            RepositoryDownloadWorker.perform_async(r.id)
          else
            CreateRepositoryWorker.perform_async('GitLab', name)
          end
        end
      end
      if names.any?
        limit = limit - 1
        REDIS.set 'gitlab-page', page_number
        recursive_gitlab_repos(page_number.to_i + 1, limit, order)
      end
    end

    private

    def self.api_client(token = nil)
      ::Gitlab.client(endpoint: 'https://gitlab.com/api/v4', private_token: token || ENV['GITLAB_KEY'])
    end

    def api_client(token = nil)
      self.class.api_client
    end

    def self.fetch_repo(full_name, token = nil)
      project = api_client(token).project(full_name)
      repo_hash = project.to_hash.with_indifferent_access.slice(:id, :description, :created_at, :name, :open_issues_count, :forks_count, :default_branch)

      repo_hash.merge!({
        host_type: 'GitLab',
        full_name: project.path_with_namespace,
        owner: {},
        fork: project.try(:forked_from_project).present?,
        updated_at: project.last_activity_at,
        stargazers_count: project.star_count,
        has_issues: project.issues_enabled,
        has_wiki: project.wiki_enabled,
        scm: 'git',
        private: project.visibility != "public",
        pull_requests_enabled: project.merge_requests_enabled,
        logo_url: project.avatar_url,
        keywords: project.tag_list,
        parent: {
          full_name: project.try(:forked_from_project).try(:path_with_namespace)
        }
      })
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end
  end
end
