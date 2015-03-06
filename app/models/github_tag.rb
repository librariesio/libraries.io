class GithubTag < ActiveRecord::Base
  belongs_to :github_repository
  validates_presence_of :name, :sha, :github_repository

  def to_s
    name
  end

  def <=>(other)
    if parsed_number.is_a?(String) || other.parsed_number.is_a?(String)
      other.number <=> number
    else
      other.parsed_number <=> parsed_number
    end
  end

  def parsed_number
    Semantic::Version.new(number) rescue number
  end

  def number
    name
  end

  def github_url
    "#{github_repository.url}/releases/tag/#{name}"
  end
end
