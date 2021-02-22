# frozen_string_literal: true
class Contribution < ApplicationRecord
  belongs_to :repository_user
  belongs_to :repository
  counter_culture :repository

  scope :with_repo, -> { joins(:repository).where('repositories.id IS NOT NULL') }

  def github_url
    "https://github.com/#{repository.full_name}/commits/master?author=#{repository_user.login}"
  end
end
