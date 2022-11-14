# frozen_string_literal: true

# == Schema Information
#
# Table name: manifests
#
#  id            :integer          not null, primary key
#  branch        :string
#  filepath      :string
#  kind          :string
#  platform      :string
#  sha           :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  repository_id :integer
#
# Indexes
#
#  index_manifests_on_created_at     (created_at)
#  index_manifests_on_repository_id  (repository_id)
#
class Manifest < ApplicationRecord
  belongs_to :repository
  has_many :repository_dependencies, dependent: :delete_all

  scope :latest, -> { order("manifests.filepath, manifests.created_at DESC").select("DISTINCT on (manifests.filepath) *") }
  scope :platform, ->(platform) { where('lower(manifests.platform) = ?', platform.try(:downcase)) }
  scope :kind, ->(kind) { where(kind: kind) }

  def repository_link
    repository.blob_url(branch) + filepath
  end
end
