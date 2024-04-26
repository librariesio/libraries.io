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
  # TODO: this table will be removed
end
