class GithubContribution < ApplicationRecord
  belongs_to :github_user#, touch: true
  belongs_to :github_repository#, touch: true
  counter_culture :github_repository

  scope :with_repo, -> { joins(:github_repository).where('github_repositories.id IS NOT NULL') }

  def github_url
    "https://github.com/#{github_repository.full_name}/commits/master?author=#{github_user.login}"
  end
end
