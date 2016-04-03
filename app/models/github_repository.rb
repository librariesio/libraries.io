class GithubRepository < ActiveRecord::Base
  STATUSES = ['Active', 'Deprecated', 'Unmaintained', 'Help Wanted', 'Removed']

  API_FIELDS = [:description, :fork, :created_at, :updated_at, :pushed_at, :homepage,
   :size, :stargazers_count, :language, :has_issues, :has_wiki, :has_pages,
   :forks_count, :mirror_url, :open_issues_count, :default_branch,
   :subscribers_count, :private]

  has_many :projects
  has_many :github_contributions, dependent: :delete_all
  has_many :contributors, through: :github_contributions, source: :github_user
  has_many :github_tags, dependent: :delete_all
  has_many :manifests, dependent: :destroy
  has_many :dependencies, through: :manifests, source: :repository_dependencies
  has_many :repository_subscriptions
  has_many :web_hooks
  has_many :github_issues, dependent: :delete_all
  has_one :readme, dependent: :delete
  belongs_to :github_organisation
  belongs_to :github_user, primary_key: :github_id, foreign_key: :owner_id
  belongs_to :source, primary_key: :full_name, foreign_key: :source_name, anonymous_class: GithubRepository
  has_many :forked_repositories, primary_key: :full_name, foreign_key: :source_name, anonymous_class: GithubRepository

  validates :full_name, uniqueness: true, if: lambda { self.full_name_changed? }
  validates :github_id, uniqueness: true, if: lambda { self.github_id_changed? }

  after_commit :update_all_info_async, on: :create

  scope :without_readme, -> { where("github_repositories.id NOT IN (SELECT github_repository_id FROM readmes)") }
  scope :with_projects, -> { joins(:projects) }
  scope :without_projects, -> { includes(:projects).where(projects: { github_repository_id: nil }) }
  scope :without_subscriptons, -> { includes(:repository_subscriptions).where(repository_subscriptions: { github_repository_id: nil }) }

  scope :fork, -> { where(fork: true) }
  scope :source, -> { where(fork: false) }

  scope :open_source, -> { where(private: false) }
  scope :from_org, lambda{ |org_id|  where(github_organisation_id: org_id) }

  scope :with_manifests, -> { joins(:manifests) }
  scope :without_manifests, -> { includes(:manifests).where(manifests: {github_repository_id: nil}) }

  scope :with_license, -> { where("github_repositories.license <> ''") }
  scope :without_license, -> {where("github_repositories.license IS ? OR github_repositories.license = ''", nil)}

  scope :interesting, -> { where('github_repositories.stargazers_count > 0').order('github_repositories.stargazers_count DESC, github_repositories.pushed_at DESC') }
  scope :uninteresting, -> { without_readme.without_manifests.without_license.where('github_repositories.stargazers_count = 0').where('github_repositories.forks_count = 0') }

  scope :recently_created, -> { where('created_at > ?', 7.days.ago)}
  scope :hacker_news, -> { order("((stargazers_count-1)/POW((EXTRACT(EPOCH FROM current_timestamp-created_at)/3600)+2,1.8)) DESC") }

  scope :maintained, -> { where('github_repositories."status" not in (?) OR github_repositories."status" IS NULL', ["Deprecated", "Removed", "Unmaintained"])}
  scope :deprecated, -> { where('github_repositories."status" = ?', "Deprecated")}
  scope :not_removed, -> { where('github_repositories."status" != ? OR github_repositories."status" IS NULL', "Removed")}
  scope :removed, -> { where('github_repositories."status" = ?', "Removed")}
  scope :unmaintained, -> { where('github_repositories."status" = ?', "Unmaintained")}

  def self.language(language)
    where('lower(github_repositories.language) = ?', language.try(:downcase))
  end

  def meta_tags
    {
      title: "#{full_name} on GitHub",
      description: description,
      image: avatar_url(200)
    }
  end

  def is_deprecated?
    status == 'Deprecated'
  end

  def is_removed?
    status == 'Removed'
  end

  def is_unmaintained?
    status == 'Unmaintained'
  end

  def maintained?
    !is_deprecated? && !is_removed? && !is_unmaintained?
  end

  def touch_projects
    projects.find_each(&:save)
  end

  def repository_dependencies
    manifests.latest.includes(repository_dependencies: :project).map(&:repository_dependencies).flatten.uniq
  end

  def owner
    github_organisation_id.present? ? github_organisation : github_user
  end

  def download_owner
    o = github_client.user(owner_name)
    if o.type == "Organization"
      if go = GithubOrganisation.create_from_github(owner_id.to_i)
        self.github_organisation_id = go.id
        save
      end
    else
      GithubUser.find_or_create_by(github_id: o.id) do |u|
        u.login = o.login
        u.user_type = o.type
      end
    end
  rescue Octokit::RepositoryUnavailable, Octokit::InvalidRepository, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway, Octokit::ClientError => e
    nil
  end

  def to_s
    full_name
  end

  def to_param
    full_name
  end

  def owner_name
    full_name.split('/')[0]
  end

  def project_name
    full_name.split('/')[1]
  end

  def color
    Languages::Language[language].try(:color)
  end

  def stars
    stargazers_count || 0
  end

  def forks
    forks_count || 0
  end

  def pages_url
    "http://#{owner_name}.github.io/#{project_name}"
  end

  def wiki_url
    "#{url}/wiki"
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

  def issues_url
    "#{url}/issues"
  end

  def contributors_url
    "#{url}/graphs/contributors"
  end

  def url
    "https://github.com/#{full_name}"
  end

  def source_url
    "https://github.com/#{source_name}"
  end

  def blob_url
    "#{url}/blob/#{default_branch}/"
  end

  def raw_url
    "#{url}/raw/#{default_branch}/"
  end

  def commits_url
    "#{url}/commits"
  end

  def readme_url
    "#{url}#readme"
  end

  def tags_url
    "#{url}/tags"
  end

  def avatar_url(size = 60)
    "https://avatars.githubusercontent.com/u/#{owner_id}?size=#{size}"
  end

  def github_client(token = nil)
    AuthToken.fallback_client(token)
  end

  def id_or_name
    github_id || full_name
  end

  def download_readme(token = nil)
    contents = {html_body: github_client(token).readme(full_name, accept: 'application/vnd.github.V3.html')}
    if readme.nil?
      create_readme(contents)
    else
      readme.update_attributes(contents)
    end
  rescue Octokit::Unauthorized, Octokit::InvalidRepository, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway, Octokit::ClientError
    nil
  end

  def update_from_github(token = nil)
    begin
      r = github_client(token).repo(id_or_name, accept: 'application/vnd.github.drax-preview+json').to_hash
      return if r.nil? || r.empty?
      self.github_id = r[:id] unless self.github_id == r[:id]
      self.full_name = r[:full_name] if self.full_name.downcase != r[:full_name].downcase
      self.owner_id = r[:owner][:id]
      self.license = Project.format_license(r[:license][:key]) if r[:license]
      self.source_name = r[:parent][:full_name] if r[:fork]
      assign_attributes r.slice(*API_FIELDS)
      save! if self.changed?
    rescue Octokit::Unauthorized, Octokit::InvalidRepository, Octokit::RepositoryUnavailable, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway, Octokit::ClientError=> e
      nil
    rescue Octokit::NotFound
      update_attribute(:status, 'Removed') if !self.private?
    end
  end

  def update_all_info_async(token = nil)
    GithubDownloadWorker.perform_async(self.id, token)
  end

  def update_all_info(token = nil)
    update_from_github(token)
    download_readme(token)
    download_tags(token)
    download_github_contributions(token)
    download_manifests(token)
    download_owner
    download_fork_source(token)
    touch_projects
  end

  def download_fork_source(token = nil)
    return true unless self.fork? && self.source.nil?
    GithubRepository.create_from_github(source_name, token)
  end

  def download_forks_async(token = nil)
    GithubDownloadForkWorker.perform_async(self.id, token)
  end

  def download_forks(token = nil)
    return true if fork?
    return true unless forks_count && forks_count > 0 && forks_count < 100
    return true if forks_count == forked_repositories.count
    AuthToken.new_client(token).forks(full_name).each do |fork|
      GithubRepository.create_from_hash(fork)
    end
  end

  def download_github_contributions(token = nil)
    contributions = github_client(token).contributors(full_name)
    return if contributions.empty?
    existing_github_contributions = github_contributions.includes(:github_user).to_a
    platform = projects.first.try(:platform)
    contributions.each do |c|
      return unless c['id']

      unless cont = existing_github_contributions.find{|c| c.github_user.try(:github_id) == c.id }
        user = GithubUser.find_or_create_by(github_id: c.id) do |u|
          u.login = c.login
          u.user_type = c.type
        end
        cont = github_contributions.find_or_create_by(github_user: user)
      end

      cont.count = c.contributions
      cont.platform = platform
      cont.save! if cont.changed?
    end
    true
  rescue Octokit::Unauthorized, Octokit::InvalidRepository, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Conflict, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway, Octokit::ClientError=> e
    nil
  end

  def download_tags(token = nil)
    existing_tag_names = github_tags.pluck(:name)
    github_client(token).refs(full_name, 'tags').each do |tag|
      return unless tag['ref']
      match = tag.ref.match(/refs\/tags\/(.*)/)
      if match
        name = match[1]
        unless existing_tag_names.include?(name)

          object = github_client(token).get(tag.object.url)

          tag_hash = {
            name: name,
            kind: tag.object.type,
            sha: tag.object.sha
          }

          # map depending on if its a commit or a tag
          case tag.object.type
          when 'commit'
            tag_hash[:published_at] = object.committer.date
          when 'tag'
            tag_hash[:published_at] = object.tagger.date
          end

          github_tags.create!(tag_hash)
        end
      end
    end
  rescue Octokit::Unauthorized, Octokit::InvalidRepository, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Conflict, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway, Octokit::ClientError=> e
    nil
  end

  def create_webhook(token)
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
  rescue Octokit::UnprocessableEntity => e
    nil
  end

  def download_manifests(token = nil)
    r = Typhoeus::Request.new("http://libhooks.herokuapp.com/v2/repos/#{full_name}",
      method: :get,
      params: { token: token },
      headers: { 'Accept' => 'application/json' }).run
    begin
      body = Oj.load(r.body)
      if body
        new_manifests = body["manifests"]
      else
        new_manifests = nil
      end
    rescue Oj::ParseError
      new_manifests = nil
    end

    if body && body['metadata']
      meta = body['metadata']

      self.has_readme       = meta['readme']['path']        if meta['readme']
      self.has_changelog    = meta['changelog']['path']     if meta['changelog']
      self.has_contributing = meta['contributing']['path']  if meta['contributing']
      self.has_license      = meta['license']['path']       if meta['license']
      self.has_coc          = meta['codeofconduct']['path'] if meta['codeofconduct']
      self.has_threat_model = meta['threatmodel']['path']   if meta['threatmodel']
      self.has_audit        = meta['audit']['path']         if meta['audit']

      save! if self.changed?
    end

    return if new_manifests.nil?

    new_manifests.each do |m|
      args = {platform: m['platform'], kind: m['type'], filepath: m['filepath'], sha: m['sha']}

      unless manifests.find_by(args)
        manifest = manifests.create(args)
        m['dependencies'].each do |dep|
          platform = manifest.platform

          project = Project.platform(platform).find_by_name(dep['name'])

          manifest.repository_dependencies.create({
            project_id: project.try(:id),
            project_name: dep['name'].try(:strip),
            platform: platform,
            requirements: dep['version'],
            kind: dep['type']
          })
        end
      end
    end

    delete_old_manifests

    repository_subscriptions.each(&:update_subscriptions)
  end

  def delete_old_manifests
    manifests.where.not(id: manifests.latest.map(&:id)).each(&:destroy)
  end

  def self.create_from_github(full_name, token = nil)
    github_client = AuthToken.new_client(token)
    repo_hash = github_client.repo(full_name, accept: 'application/vnd.github.drax-preview+json').to_hash
    return false if repo_hash.nil? || repo_hash.empty?
    create_from_hash(repo_hash)
  rescue Octokit::Unauthorized, Octokit::InvalidRepository, Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Conflict, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway, Octokit::ClientError => e
    nil
  end

  def self.create_from_hash(repo_hash)
    repo_hash = repo_hash.to_hash
    ActiveRecord::Base.transaction do
      g = GithubRepository.find_by(github_id: repo_hash[:id])
      g = GithubRepository.find_by('lower(full_name) = ?', repo_hash[:full_name].downcase) if g.nil?
      g = GithubRepository.new(github_id: repo_hash[:id], full_name: repo_hash[:full_name]) if g.nil?
      g.owner_id = repo_hash[:owner][:id]
      g.full_name = repo_hash[:full_name] if g.full_name.downcase != repo_hash[:full_name].downcase
      g.github_id = repo_hash[:id] if g.github_id.nil?
      g.license = repo_hash[:license][:key] if repo_hash[:license]
      g.source_name = repo_hash[:parent][:full_name] if repo_hash[:fork] && repo_hash[:parent]
      g.assign_attributes repo_hash.slice(*GithubRepository::API_FIELDS)

      if g.changed?
        return g.save ? g : nil
      else
        return g
      end
    end
  rescue ActiveRecord::RecordNotUnique
    nil
  end
end
