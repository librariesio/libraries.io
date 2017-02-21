module RepositoryHost
  class Github < Base
    IGNORABLE_EXCEPTIONS = [Octokit::Unauthorized, Octokit::InvalidRepository, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Conflict, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway, Octokit::ClientError]

    def avatar_url(size = 60)
      "https://avatars.githubusercontent.com/u/#{repository.owner_id}?size=#{size}"
    end

    def create_webhook(token = nil)
      api_client(token).create_hook(
        full_name,
        'web',
        {
          :url => 'https://libraries.io/hooks/github',
          :content_type => 'json'
        },
        {
          :events => ['push', 'pull_request'],
          :active => true
        }
      )
    rescue Octokit::UnprocessableEntity
      nil
    end

    def download_contributions(token = nil)
      gh_contributions = api_client(token).contributors(repository.full_name)
      return if gh_contributions.empty?
      existing_contributions = repository.contributions.includes(:github_user).to_a
      platform = repository.projects.first.try(:platform)
      gh_contributions.each do |c|
        next unless c['id']
        cont = existing_contributions.find{|cnt| cnt.github_user.try(:github_id) == c.id }
        unless cont
          user = GithubUser.create_from_github(c)
          cont = repository.contributions.find_or_create_by(github_user: user)
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
      return true if repository.forks_count == repository.forked_repositories.count
      AuthToken.new_client(token).forks(repository.full_name).each do |fork|
        Repository.create_from_hash(fork)
      end
    end

    def download_issues(token = nil)
      api_client = AuthToken.new_client(token)
      issues = api_client.issues(full_name, state: 'all')
      issues.each do |issue|
        Issue.create_from_hash(repository, issue)
      end
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def download_owner
      return if repository.owner && repository.owner.login == repository.owner_name
      o = api_client.user(repository.owner_name)
      if o.type == "Organization"
        go = GithubOrganisation.create_from_github(repository.owner_id.to_i)
        if go
          repository.github_organisation_id = go.id
          repository.save
        end
      else
        GithubUser.create_from_github(o)
      end
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def download_readme(token = nil)
      contents = {
        html_body: api_client(token).readme(repository.full_name, accept: 'application/vnd.github.V3.html')
      }

      if repository.readme.nil?
        repository.create_readme(contents)
      else
        repository.readme.update_attributes(contents)
      end
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    private

    def api_client(token = nil)
      AuthToken.fallback_client(token)
    end
  end
end
