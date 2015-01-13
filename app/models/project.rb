class Project < ActiveRecord::Base
  validates_presence_of :name, :platform

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
    licenses.join(',').gsub('["', '').gsub('"]', '').split(',')
           .map(&:downcase).map(&:strip).reject(&:blank?).uniq.sort
  end

  ## relations
  # versions => dependencies
  # repository
  # licenses
  # users
end
