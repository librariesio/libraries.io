class Manifest < ActiveRecord::Base
  belongs_to :github_repository
  has_many :repository_dependencies, dependent: :destroy

  def github_link
    github_repository.blob_url + path
  end
end
