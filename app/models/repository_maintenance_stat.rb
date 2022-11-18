# frozen_string_literal: true

# == Schema Information
#
# Table name: repository_maintenance_stats
#
#  id            :bigint           not null, primary key
#  category      :string
#  value         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  repository_id :bigint
#
# Indexes
#
#  index_repository_maintenance_stats_on_repository_and_category  (repository_id,category) UNIQUE
#  index_repository_maintenance_stats_on_repository_id            (repository_id)
#
class RepositoryMaintenanceStat < ApplicationRecord
    belongs_to :repository
end
