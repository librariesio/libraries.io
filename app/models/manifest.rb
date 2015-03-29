class Manifest < ActiveRecord::Base
  belongs_to :user
  has_many :subscriptions, dependent: :destroy

  def repository
    user.github_client.repo(repository_id) if repository_id.present?
  end
end
