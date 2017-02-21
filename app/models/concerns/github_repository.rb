module GithubRepository
  extend ActiveSupport::Concern

  included do
    IGNORABLE_GITHUB_EXCEPTIONS = [Octokit::Unauthorized, Octokit::InvalidRepository, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Conflict, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway, Octokit::ClientError]

    def self.create_from_github(full_name, token = nil)
      github_client = AuthToken.new_client(token)
      repo_hash = github_client.repo(full_name, accept: 'application/vnd.github.drax-preview+json').to_hash
      return false if repo_hash.nil? || repo_hash.empty?
      create_from_hash(repo_hash)
    rescue *IGNORABLE_GITHUB_EXCEPTIONS
      nil
    end
  end

  def download_github_owner
    return if owner && owner.login == owner_name
    o = github_client.user(owner_name)
    if o.type == "Organization"
      go = GithubOrganisation.create_from_github(owner_id.to_i)
      if go
        self.github_organisation_id = go.id
        save
      end
    else
      GithubUser.create_from_github(o)
    end
  rescue *IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def download_github_fork_source(token = nil)
    return true unless self.fork? && self.source.nil?
    Repository.create_from_github(source_name, token)
  end

  def download_github_readme(token = nil)
    contents = {html_body: github_client(token).readme(full_name, accept: 'application/vnd.github.V3.html')}
    if readme.nil?
      create_readme(contents)
    else
      readme.update_attributes(contents)
    end
  rescue *IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def download_github_issues(token = nil)
    github_client = AuthToken.new_client(token)
    issues = github_client.issues(full_name, state: 'all')
    issues.each do |issue|
      Issue.create_from_hash(self, issue)
    end
  rescue *IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def github_client(token = nil)
    AuthToken.fallback_client(token)
  end

  def github_create_webhook(token = nil)
    github_client(token).create_hook(
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

  def update_from_github(token = nil)
    begin
      r = AuthToken.new_client(token).repo(id_or_name, accept: 'application/vnd.github.drax-preview+json').to_hash
      return unless r.present?
      self.uuid = r[:id] unless self.uuid == r[:id]
       if self.full_name.downcase != r[:full_name].downcase
         clash = Repository.host('GitHub').where('lower(full_name) = ?', r[:full_name].downcase).first
         if clash && (!clash.update_from_github(token) || clash.status == "Removed")
           clash.destroy
         end
         self.full_name = r[:full_name]
       end
      self.owner_id = r[:owner][:id]
      self.license = Project.format_license(r[:license][:key]) if r[:license]
      self.source_name = r[:parent][:full_name] if r[:fork]
      assign_attributes r.slice(*API_FIELDS)
      save! if self.changed?
    rescue Octokit::NotFound
      update_attribute(:status, 'Removed') if !self.private?
    rescue *IGNORABLE_GITHUB_EXCEPTIONS
      nil
    end
  end

  def download_github_tags(token = nil)
    existing_tag_names = tags.pluck(:name)
    tags = github_client(token).refs(full_name, 'tags')
    Array(tags).each do |tag|
      next unless tag && tag.is_a?(Sawyer::Resource) && tag['ref']
      download_github_tag(token, tag, existing_tag_names)
    end
  rescue *IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def download_github_tag(token, tag, existing_tag_names)
    match = tag.ref.match(/refs\/tags\/(.*)/)
    return unless match
    name = match[1]
    return if existing_tag_names.include?(name)

    object = github_client(token).get(tag.object.url)

    tag_hash = {
      name: name,
      kind: tag.object.type,
      sha: tag.object.sha
    }

    case tag.object.type
    when 'commit'
      tag_hash[:published_at] = object.committer.date
    when 'tag'
      tag_hash[:published_at] = object.tagger.date
    end

    tags.create!(tag_hash)
  end

  def download_forks_async(token = nil)
    GithubDownloadForkWorker.perform_async(self.id, token)
  end

  def download_forks(token = nil)
    return unless host_type == 'GitHub'
    return true if fork?
    return true unless forks_count && forks_count > 0 && forks_count < 100
    return true if forks_count == forked_repositories.count
    AuthToken.new_client(token).forks(full_name).each do |fork|
      Repository.create_from_hash(fork)
    end
  end

  def download_github_contributions(token = nil)
    gh_contributions = github_client(token).contributors(full_name)
    return if gh_contributions.empty?
    existing_contributions = contributions.includes(:github_user).to_a
    platform = projects.first.try(:platform)
    gh_contributions.each do |c|
      next unless c['id']
      cont = existing_contributions.find{|cnt| cnt.github_user.try(:github_id) == c.id }
      unless cont
        user = GithubUser.create_from_github(c)
        cont = contributions.find_or_create_by(github_user: user)
      end

      cont.count = c.contributions
      cont.platform = platform
      cont.save! if cont.changed?
    end
    true
  rescue *IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def github_contributions_count
    contributions_count # legacy alias
  end

  def github_id
    uuid # legacy alias
  end
end
