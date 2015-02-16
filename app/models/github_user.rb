class GithubUser < ActiveRecord::Base
  has_many :github_contributions

  def avatar_url(size = 60)
    "https://avatars.githubusercontent.com/u/#{github_id}?size=#{size}"
  end

  def github_url
    "https://github.com/#{login}"
  end

  def to_s
    login
  end

  def to_param
    login.downcase
  end

  def repositories
    GithubRepository.where('full_name ILIKE ?', "#{login}/%")
  end

  def self.top_for(platform, limit = 5)
    GithubContribution.where(platform: platform).select('sum(count) as count, github_user_id')
      .group('github_user_id')
      .order('count DESC')
      .limit(limit)
      .includes(:github_user)
      .map(&:github_user)
  end

  def self.top(limit = 5)
    GithubContribution.select('sum(count) as count, github_user_id')
      .group('github_user_id')
      .order('count DESC')
      .limit(limit)
      .includes(:github_user)
      .map(&:github_user)
  end
end
