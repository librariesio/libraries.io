# frozen_string_literal: true

# == Schema Information
#
# Table name: repository_dependencies
#
#  id            :bigint           not null, primary key
#  kind          :string
#  optional      :boolean
#  platform      :string
#  project_name  :string
#  requirements  :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  manifest_id   :integer
#  project_id    :integer
#  repository_id :integer
#
# Indexes
#
#  index_repository_dependencies_on_manifest_id              (manifest_id)
#  index_repository_dependencies_on_project_created_at_date  (project_id, ((created_at)::date))
#  index_repository_dependencies_on_project_id               (project_id)
#  index_repository_dependencies_on_repository_id            (repository_id)
#
class RepositoryDependency < ApplicationRecord
end
