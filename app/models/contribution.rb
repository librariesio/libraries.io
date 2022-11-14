# frozen_string_literal: true

# == Schema Information
#
# Table name: contributions
#
#  id                 :integer          not null, primary key
#  count              :integer
#  platform           :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  repository_id      :integer
#  repository_user_id :integer
#
# Indexes
#
#  index_contributions_on_repository_id_and_user_id  (repository_id,repository_user_id)
#  index_contributions_on_repository_user_id         (repository_user_id)
#
class Contribution < ApplicationRecord
  belongs_to :repository_user
  belongs_to :repository
  counter_culture :repository

  scope :with_repo, -> { joins(:repository).where('repositories.id IS NOT NULL') }

  def github_url
    "https://github.com/#{repository.full_name}/commits/master?author=#{repository_user.login}"
  end
end
