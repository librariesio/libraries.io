class Project < ActiveRecord::Base
  validates_presence_of :name, :platform

  #  validate unique name and platform (case?)

  # TODO validate homepage format

  def to_param
    "#{id}-#{name.parameterize}"
  end

  has_many :versions

  scope :platform, ->(platform) { where platform: platform }

  def self.search(query)
    q = "%#{query}%"
    where('name ILIKE ? or keywords ILIKE ?', q, q).order(:created_at)
  end

  def self.license(license)
    where('licenses ILIKE ?', "%#{license}%")
  end

  def self.licenses
    licenses = Project.select('DISTINCT licenses').map(&:licenses).compact
    licenses.join(',').split(',')
      .map(&:downcase).map(&:strip).reject(&:blank?).uniq.sort
  end

  def extract_github_url
    url = repository
    github_regex = /^(((https|http|git)?:\/\/(www\.)?)|git@)github.com(:|\/)/i
    return false unless url.match(github_regex)
    url.gsub!(github_regex, '').strip!
    url.gsub!(/(\.git|\/)$/i, '')
    url = url.split('/')[0..1]
    return false unless url.length == 2
    "https://github.com/#{url.join('/')}"
  end

  ## relations
  # versions => dependencies
  # repository
  # licenses
  # users
end
