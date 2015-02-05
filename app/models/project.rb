class Project < ActiveRecord::Base
  validates_presence_of :name, :platform

  #  validate unique name and platform (case?)

  # TODO validate homepage format

  def to_param
    { name: name, platform: platform.downcase }
  end

  def to_s
    name
  end

  has_many :versions
  belongs_to :github_repository

  scope :platform, ->(platform) { where('platform ILIKE ?', platform) }
  scope :with_repository_url, -> { where("repository_url <> ''") }
  scope :with_repo, -> { includes(:github_repository).where('github_repositories.id IS NOT NULL') }
  scope :without_repo, -> { where(github_repository_id: nil) }

  def self.undownloaded_repos
    with_repository_url.without_repo
  end

  def self.search(query)
    q = "%#{query}%"
    where('name ILIKE ? or keywords ILIKE ?', q, q).order(:created_at)
  end

  def self.license(license)
    where('licenses ILIKE ?', "%#{license}%")
  end

  def self.language(language)
    joins(:github_repository).where('github_repositories.language ILIKE ?', language)
  end

  def self.licenses
    licenses = Project.select('DISTINCT licenses').map(&:licenses).compact
    licenses.join(',').split(',')
      .map(&:downcase).map(&:strip).reject(&:blank?).uniq.sort
  end

  def self.popular_platforms(limit = 5)
    select('count(*) count, platform')
    .group('platform')
    .order('count DESC')
    .limit(limit)
  end

  def self.popular_licenses
    where("licenses <> ''")
      .where("licenses != 'UNKNOWN'")
      .where("licenses != 'OtherLicense'")
      .select('count(*) count, licenses')
      .group('licenses')
      .order('count DESC')
  end

  def github_client
    AuthToken.client
  end

  def update_github_repo
    name_with_owner = github_name_with_owner
    p name_with_owner
    return false unless name_with_owner

    begin
      r = github_client.repo(name_with_owner).to_hash
      return false if r.nil? || r.empty?
      g = GithubRepository.find_or_initialize_by(r.slice(:full_name))
      g.owner_id = r[:owner][:id]
      g.assign_attributes r.slice(*github_keys)
      g.save
      self.github_repository_id = g.id
      self.save
    rescue Octokit::NotFound, Octokit::Forbidden => e
      begin
        response = Net::HTTP.get_response(URI(github_url))
        if response.code.to_i == 301
          self.repository_url = URI(response['location']).to_s
          update_github_repo
        else
          p response.code.to_i
          p e
        end
      rescue URI::InvalidURIError => e
        p e
      end
    end
  end

  def download_github_contributions
    return false unless github_repository
    github_repository.download_github_contributions
  end

  def github_keys
    [:description, :fork, :created_at, :updated_at, :pushed_at, :homepage,
     :size, :stargazers_count, :language, :has_issues, :has_wiki, :has_pages,
     :forks_count, :mirror_url, :open_issues_count, :default_branch,
     :subscribers_count]
  end

  def github_url
    return false if repository_url.blank? || github_name_with_owner.blank?
    "https://github.com/#{github_name_with_owner}"
  end

  def github_name_with_owner
    url = repository_url.clone
    github_regex = /(((https|http|git|ssh)?:\/\/(www\.)?)|ssh:\/\/git@|https:\/\/git@|scm:git:git@)(github.com|raw.githubusercontent.com)(:|\/)/i
    return nil unless url.match(github_regex)
    url.gsub!(github_regex, '').strip!
    url.gsub!(/(\.git|\/)$/i, '')
    url.gsub!(' ', '')
    url = url.split('/').reject(&:blank?)[0..1]
    return nil unless url.length == 2
    url.join('/')
  end

  def bitbucket_url
    url = repository_url.clone
    github_regex = /^(((https|http|git)?:\/\/(www\.)?)|git@)bitbucket.org(:|\/)/i
    return nil unless url.match(github_regex)
    url.gsub!(github_regex, '').strip!
    url.gsub!(/(\.git|\/)$/i, '')
    url = url.split('/')[0..1]
    return nil unless url.length == 2
    "https://bitbucket.org/#{bitbucket_name_with_owner}"
  end

  def bitbucket_name_with_owner
    github_regex = /^(((https|http|git)?:\/\/(www\.)?)|git@)bitbucket.org(:|\/)/i
    return nil unless url.match(github_regex)
    url.gsub!(github_regex, '').strip!
    url.gsub!(/(\.git|\/)$/i, '')
    url = url.split('/')[0..1]
    return nil unless url.length == 2
    url.join('/')
  end
end
