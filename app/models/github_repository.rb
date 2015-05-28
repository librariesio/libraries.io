class GithubRepository < ActiveRecord::Base
  # validations (presense and uniqueness)

  API_FIELDS = [:full_name, :description, :fork, :created_at, :updated_at, :pushed_at, :homepage,
   :size, :stargazers_count, :language, :has_issues, :has_wiki, :has_pages,
   :forks_count, :mirror_url, :open_issues_count, :default_branch,
   :subscribers_count, :private]

  has_many :projects
  has_many :github_contributions
  has_many :github_tags
  has_many :manifests
  has_many :dependencies, through: :manifests, source: :repository_dependencies
  has_many :repository_subscriptions
  has_one :readme
  belongs_to :github_organisation
  belongs_to :github_user, primary_key: :github_id, foreign_key: :owner_id

  after_commit :update_all_info_async, on: :create

  scope :without_readme, -> { where("id NOT IN (SELECT github_repository_id FROM readmes)") }
  scope :with_projects, -> { joins(:projects) }
  scope :with_manifests, -> { joins(:manifests) }
  scope :fork, -> { where(fork: true) }
  scope :source, -> { where(fork: false) }
  scope :open_source, -> { where(private: false) }

  def repository_dependencies
    manifests.latest.includes(:repository_dependencies).map(&:repository_dependencies).flatten.uniq
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
      user = GithubUser.find_or_create_by(github_id: o.id) do |u|
        u.login = o.login
        u.user_type = o.type
      end
      user.dowload_from_github
      user
    end
  rescue Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
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
    stargazers_count
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
  rescue Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway
    nil
  end

  def update_from_github(token = nil)
    begin
      r = github_client(token).repo(id_or_name, accept: 'application/vnd.github.drax-preview+json').to_hash
      return if r.nil? || r.empty?
      self.github_id = r[:id]
      self.owner_id = r[:owner][:id]
      self.license = Project.format_license(r[:license][:key]) if r[:license]
      self.source_name = r[:parent][:full_name] if r[:fork]
      assign_attributes r.slice(*API_FIELDS)
      save
    rescue Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
      begin
        response = Net::HTTP.get_response(URI(url))
        if response.code.to_i == 301
          self.full_name = GithubRepository.extract_full_name URI(response['location']).to_s
          update_from_github(token)
        end
      rescue URI::InvalidURIError => e
        p e
      end
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
  rescue
    nil
  end

  def self.extract_full_name(url)
    return nil if url.nil?
    github_regex = /(((https|http|git|ssh)?:\/\/(www\.)?)|ssh:\/\/git@|https:\/\/git@|scm:git:git@|git@)(github.com|raw.githubusercontent.com)(:|\/)/i
    return nil unless url.match(github_regex)
    url = url.gsub(github_regex, '').strip
    url = url.gsub(/(\.git|\/)$/i, '')
    url = url.gsub(' ', '')
    url = url.gsub(/^scm:git:/, '')
    url = url.split('/').reject(&:blank?)[0..1]
    return nil unless url.length == 2
    url.join('/')
  end

  def download_github_contributions(token = nil)
    contributions = github_client(token).contributors(full_name)
    return if contributions.empty?
    contributions.each do |c|
      return unless c['id']
      user = GithubUser.find_or_create_by(github_id: c.id) do |u|
        u.login = c.login
        u.user_type = c.type
      end
      cont = github_contributions.find_or_create_by(github_user: user)
      cont.count = c.contributions
      cont.platform = projects.first.platform if projects.any?
      cont.save
    end
  rescue Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Conflict, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
    nil
  end

  def download_tags(token = nil)
    github_client(token).refs(full_name, 'tags').each do |tag|
      return unless tag['ref']
      match = tag.ref.match(/refs\/tags\/(.*)/)
      if match
        name = match[1]
        if github_tags.find_by_name(name).nil?

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
  rescue Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Conflict, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
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
  end

  def remove_hook(id, token)
    github_client(token).remove_hook(full_name, id)
  end

  def download_manifests(token = nil)
    r = Typhoeus::Request.new("http://ci.libraries.io/repos/#{full_name}",
      method: :get,
      params: { token: token },
      headers: { 'Accept' => 'application/json' }).run
    new_manifests = Oj.load(r.body)["manifests"]
    return if new_manifests.nil?
    new_manifests.each do |m|
      args = m.slice('name', 'path', 'sha')
      if manifests.find_by(args)
        # not much
      else
        manifest = manifests.create(args)
        m['deps'].each do |dep, requirements|
          platform = manifest.name
          project = Project.platform(platform).find_by_name(dep)
          manifest.repository_dependencies.create({
            project_id: project.try(:id),
            project_name: dep,
            platform: platform,
            requirements: requirements,
            kind: 'normal'
          })
        end
      end
    end

    repository_subscriptions.each(&:update_subscriptions)
  end

  def self.create_from_github(full_name, token = nil)
    github_client = AuthToken.new_client(token)
    r = github_client.repo(full_name, accept: 'application/vnd.github.drax-preview+json').to_hash
    return false if r.nil? || r.empty?
    g = GithubRepository.find_or_initialize_by(r.slice(:full_name))
    g.owner_id = r[:owner][:id]
    g.github_id = r[:id]
    g.license = r[:license][:key] if r[:license]
    g.source_name = r[:parent][:full_name] if r[:fork]
    g.assign_attributes r.slice(*GithubRepository::API_FIELDS)
    g.save
  rescue Octokit::RepositoryUnavailable, Octokit::NotFound, Octokit::Conflict, Octokit::Forbidden, Octokit::InternalServerError, Octokit::BadGateway => e
    nil
  end
end
