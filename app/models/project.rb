class Project < ActiveRecord::Base
  require 'typhoeus/adapters/faraday'
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  validates_presence_of :name, :platform

  #  validate unique name and platform (case?)

  # TODO validate homepage format

  has_many :versions
  belongs_to :github_repository

  scope :platform, ->(platform) { where('platform ILIKE ?', platform) }
  scope :with_repository_url, -> { where("repository_url <> ''") }
  scope :with_repo, -> { includes(:github_repository).where('github_repositories.id IS NOT NULL') }
  scope :without_repo, -> { where(github_repository_id: nil) }
  scope :with_github_url, -> { where('repository_url ILIKE ?', '%github.com%') }

  before_save :normalize_licenses

  def to_param
    { name: name, platform: platform.downcase }
  end

  def to_s
    name
  end

  def self.undownloaded_repos
    with_github_url.without_repo
  end

  def self.license(license)
    where('? = ANY("normalized_licenses")', license)
  end

  def self.language(language)
    joins(:github_repository).where('github_repositories.language ILIKE ?', language)
  end

  def self.popular_platforms(limit = 5)
    select('count(*) count, platform')
    .group('platform')
    .order('count DESC')
    .limit(limit)
  end

  def self.popular_licenses
    where("normalized_licenses != '{}'")
      .select('count(*) count, unnest(normalized_licenses) as license')
      .where('NOT (? = ANY("normalized_licenses"))', 'Other')
      .group('license')
      .order('count DESC')
  end

  def normalize_licenses
    if licenses.blank?
      normalized = []
    elsif licenses.length > 150
      normalized = ['Other']
    else
      normalized = licenses.split(',').map do |license|
        Spdx.find(license).try(:id)
      end.compact
      normalized = ['Other'] if normalized.empty?
    end
    self.normalized_licenses = normalized
  end

  def update_github_repo
    name_with_owner = github_name_with_owner
    if name_with_owner
      puts name_with_owner
    else
      puts repository_url
      return false
    end

    begin
      r = AuthToken.client.repo(name_with_owner).to_hash
      return false if r.nil? || r.empty?
      g = GithubRepository.find_or_initialize_by(r.slice(:full_name))
      g.owner_id = r[:owner][:id]
      g.assign_attributes r.slice(*GithubRepository::API_FIELDS)
      g.save
      self.github_repository_id = g.id
      self.save
    rescue Octokit::NotFound, Octokit::Forbidden => e
      begin
        response = Net::HTTP.get_response(URI(github_url))
        if response.code.to_i == 301
          self.repository_url = URI(response['location']).to_s
          update_github_repo
        end
      rescue URI::InvalidURIError => e
        p e
      end
    end
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
    url.gsub!(/^scm:git:/, '')
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
