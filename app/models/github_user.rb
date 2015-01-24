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
    "#{id}-#{login}"
  end

  def self.top_for(platform, limit = 5)
    GithubContribution.where(platform: platform)
      .group_by(&:github_user)
      .map{|k,v| [k,v.sum(&:count)]}
      .sort_by{|a| a[1] }.reverse.first(limit)
  end
end
