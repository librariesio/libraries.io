# frozen_string_literal: true

module RepositoryHost
  class Github < Base
    NOT_FOUND_EXCEPTIONS = [
      Octokit::InvalidRepository,
      Octokit::RepositoryUnavailable,
      Octokit::NotFound,
      Octokit::UnavailableForLegalReasons,
    ].freeze

    IGNORABLE_EXCEPTIONS = ([
      Octokit::Unauthorized,
      Octokit::Conflict,
      Octokit::Forbidden,
      Octokit::InternalServerError,
      Octokit::BadGateway,
      Octokit::ClientError,
    ] + NOT_FOUND_EXCEPTIONS).freeze

    def self.api_missing_error_class
      Octokit::NotFound
    end

    def avatar_url(size = 60)
      "https://github.com/#{repository.owner_name}.png?size=#{size}"
    end

    def domain
      "https://github.com"
    end

    def watchers_url
      "#{url}/watchers"
    end

    def forks_url
      "#{url}/network"
    end

    def stargazers_url
      "#{url}/stargazers"
    end

    def contributors_url
      "#{url}/graphs/contributors"
    end

    def blob_url(sha = nil)
      sha ||= repository.default_branch
      "#{url}/blob/#{sha}/"
    end

    def commits_url(author = nil)
      author_param = author.present? ? "?author=#{author}" : ""
      "#{url}/commits#{author_param}"
    end

    def self.fetch_repo(id_or_name, token = nil)
      id_or_name = id_or_name.to_i if id_or_name.match(/\A\d+\Z/)
      hash = AuthToken.fallback_client(token).repo(id_or_name, accept: "application/vnd.github.drax-preview+json,application/vnd.github.mercy-preview+json").to_hash
      hash[:keywords] = hash[:topics]
      hash[:host_type] = "GitHub"
      hash[:scm] = "git"
      hash[:status] = "Unmaintained" if hash[:archived]
      hash
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def get_file_list(token = nil)
      tree = api_client(token).tree(repository.full_name, repository.default_branch, recursive: true).tree
      tree.select { |item| item.type == "blob" }.map(&:path)
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def get_file_contents(path, token = nil)
      file = api_client(token).contents(repository.full_name, path: path)
      {
        sha: file.sha,
        content: file.content.present? ? Base64.decode64(file.content) : file.content,
      }
    rescue URI::InvalidURIError
      nil
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def create_webhook(token = nil)
      api_client(token).create_hook(
        repository.full_name,
        "web",
        {
          url: "https://libraries.io/hooks/github",
          content_type: "json",
        },
        {
          events: %w[push pull_request],
          active: true,
        }
      )
    rescue Octokit::UnprocessableEntity
      nil
    end

    def download_contributions(token = nil)
      return if repository.fork?

      gh_contributions = api_client(token).contributors(repository.full_name)
      return if gh_contributions.empty?

      existing_contributions = repository.contributions.includes(:repository_user).to_a
      platform = repository.projects.first.try(:platform)
      gh_contributions.each do |c|
        next unless c["id"]

        cont = existing_contributions.find { |cnt| cnt.repository_user.try(:uuid) == c.id.to_s }
        unless cont
          user = RepositoryUser.create_from_host("GitHub", c)
          cont = repository.contributions.find_or_create_by(repository_user: user)
        end

        cont.count = c.contributions
        cont.platform = platform
        cont.save! if cont.changed?
      end
      true
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def download_forks(token = nil)
      return true if repository.fork?
      return true unless repository.forks_count && repository.forks_count > 0 && repository.forks_count < 100
      return true if repository.forks_count == repository.forked_repositories.host(repository.host_type).count

      AuthToken.new_client(token).forks(repository.full_name).each do |fork|
        Repository.create_from_hash(fork)
      end
    end

    def retrieve_commits(token = nil)
      api_client(token).commits(repository.full_name)
    end

    def download_owner
      return if repository.owner && repository.repository_user_id && repository.owner.login == repository.owner_name

      o = api_client.user(repository.owner_name)
      if o.type == "Organization"
        go = RepositoryOrganisation.create_from_host("GitHub", o)
        if go
          repository.repository_organisation_id = go.id
          repository.repository_user_id = nil
          repository.save
        end
      else
        u = RepositoryUser.create_from_host("GitHub", o)
        if u
          repository.repository_user_id = u.id
          repository.repository_organisation_id = nil
          repository.save
        end
      end
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def download_readme(token = nil)
      contents = api_client(token)
        .readme(repository.full_name, accept: "application/vnd.github.V3.html")
        .force_encoding(Encoding::UTF_8)

      if repository.reload_readme.nil?
        repository.create_readme(html_body: contents)
      else
        repository.readme.update(html_body: contents)
      end
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def download_tags(token = nil)
      existing_tag_names = repository.tags.pluck(:name)
      tags = api_client(token).refs(repository.full_name, "tags")
      Array(tags).each do |tag|
        next unless tag.is_a?(Sawyer::Resource) && tag["ref"]

        download_tag(token, tag, existing_tag_names)
      end
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def download_tag(token, tag, existing_tag_names)
      match = tag.ref.match(/refs\/tags\/(.*)/)
      return unless match

      name = match[1]
      return if existing_tag_names.include?(name)

      object = api_client(token).get(tag.object.url)

      tag_hash = {
        name: name,
        kind: tag.object.type,
        sha: tag.object.sha,
      }

      case tag.object.type
      when "commit"
        tag_hash[:published_at] = object.committer.date
      when "tag"
        tag_hash[:published_at] = object.tagger.date
      end

      repository.tags.create(tag_hash)
    end

    def gather_maintenance_stats
      if repository.host_type != "GitHub" || repository.owner_name.blank? || repository.project_name.blank?
        repository.repository_maintenance_stats.destroy_all
        return []
      end

      # use api_client methods?
      v4_client = AuthToken.v4_client
      v3_client = AuthToken.client({ auto_paginate: false })
      now = DateTime.current

      # We have a valid token to run the queries so
      # set refreshed_at time so we don't try and refresh
      # this repository again if the information is bad
      repository.update!(maintenance_stats_refreshed_at: now)

      # check to see if this is still a valid GitHub repository
      # if it returns a nil value then delete the existing
      # stats since they are no longer valid and skip trying to query them
      begin
        v3_client.repo(repository.full_name)
      rescue *NOT_FOUND_EXCEPTIONS => e
        # check for one of the not found errors from Octokit
        # but ignore any other communication errors to GitHub

        StructuredLog.capture(
          "GITHUB_STAT_REPO_NOT_FOUND",
          {
            repository_name: repository.full_name,
            error_message: e.message,
          }
        )

        repository.repository_maintenance_stats.destroy_all
        return []
      end

      metrics = []

      result = MaintenanceStats::Queries::Github::RepoReleasesQuery.new(v4_client).query(params: { owner: repository.owner_name, repo_name: repository.project_name, end_date: now - 1.year })
      metrics << MaintenanceStats::Stats::Github::ReleaseStats.new(result).fetch_stats

      result = MaintenanceStats::Queries::Github::CommitCountQuery.new(v4_client).query(params: { owner: repository.owner_name, repo_name: repository.project_name, start_date: now })
      metrics << MaintenanceStats::Stats::Github::CommitsStat.new(result).fetch_stats

      result = MaintenanceStats::Queries::Github::RepositoryContributorStatsQuery.new(v3_client).query(params: { full_name: repository.full_name })
      metrics << MaintenanceStats::Stats::Github::V3ContributorCountStats.new(result).fetch_stats

      result = MaintenanceStats::Queries::Github::IssuesQuery.new(v4_client).query(params: { owner: repository.owner_name, repo_name: repository.project_name, start_date: now })
      metrics << MaintenanceStats::Stats::Github::IssueStats.new(result).fetch_stats

      add_metrics_to_repo(metrics)

      metrics
    end

    private

    def api_client(token = nil)
      AuthToken.fallback_client(token)
    end
  end
end
