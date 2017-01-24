class GithubContribution < ApplicationRecord
  belongs_to :github_user
  belongs_to :repository, foreign_key: "github_repository_id"
  counter_culture :repository

  scope :with_repo, -> { joins(:repository).where('github_repositories.id IS NOT NULL') }

  def github_url
    "https://github.com/#{repository.full_name}/commits/master?author=#{github_user.login}"
  end
end
