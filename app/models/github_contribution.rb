class GithubContribution < ActiveRecord::Base
  belongs_to :github_user
  belongs_to :github_repository

  def github_url
    "https://github.com/#{github_repository.full_name}/commits/master?author=#{github_user.login}"
  end
end
