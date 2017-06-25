class Manifest < ApplicationRecord
  belongs_to :repository
  has_many :repository_dependencies, dependent: :delete_all

  after_save :denormalize_repository_dependencies

  scope :latest, -> { order("manifests.filepath, manifests.created_at DESC").select("DISTINCT on (manifests.filepath) *") }
  scope :platform, ->(platform) { where('lower(manifests.platform) = ?', platform.try(:downcase)) }
  scope :kind, ->(kind) { where(kind: kind) }

  def repository_link
    repository.blob_url(branch) + filepath
  end

  def denormalize_repository_dependencies
    RepositoryDependency.where(repository_id: repository_id).find_each do |dependency|
      dependency.repository_id = nil
      dependency.save!
    end

    repository_dependencies.find_each do |dependency|
      dependency.repository_id = repository_id
      dependency.save!
    end
  end
end
