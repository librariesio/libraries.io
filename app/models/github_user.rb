class GithubUser < ActiveRecord::Base
  has_many :github_contributions
  has_many :github_repositories, primary_key: :github_id, foreign_key: :owner_id

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
end
