class Project < ActiveRecord::Base
  include Searchable

  validates_presence_of :name, :platform

  #  validate unique name and platform (case?)

  has_many :versions
  belongs_to :github_repository

  scope :platform, ->(platform) { where('lower(platform) = ?', platform.downcase) }
  scope :with_homepage, -> { where("homepage <> ''") }
  scope :with_repository_url, -> { where("repository_url <> ''") }
  scope :without_repository_url, -> { where("repository_url IS ? OR repository_url = ''", nil) }
  scope :with_repo, -> { includes(:github_repository).where('github_repositories.id IS NOT NULL') }
  scope :without_repo, -> { where(github_repository_id: nil) }
  scope :with_github_url, -> { where('repository_url ILIKE ?', '%github.com%') }

  before_save :normalize_licenses
  after_create :update_github_repo

  def to_param
    { name: name, platform: platform.downcase }
  end

  def to_s
    name
  end

  def stars
    github_repository.try(:stargazers_count) || 0
  end

  def language
    github_repository.try(:language)
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

  def self.popular_languages(options = {})
    search('*', options).response.facets[:languages][:terms]
  end

  def self.popular_platforms(options = {})
    search('*', options).response.facets[:platforms][:terms]
  end

  def self.popular_licenses(options = {})
    search('*', options).response.facets[:licenses][:terms].reject{ |t| t.term == 'Other' }
  end

  def self.popular(options = {})
    search('*', options.merge(sort: 'stars', order: 'desc')).records
  end

  def self.popular_licenses_sql
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
    return nil if repository_url.blank? || github_name_with_owner.blank?
    "https://github.com/#{github_name_with_owner}"
  end

  def github_name_with_owner
    GithubRepository.extract_full_name repository_url
  end
end
