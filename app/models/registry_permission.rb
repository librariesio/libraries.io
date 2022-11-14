# frozen_string_literal: true

# == Schema Information
#
# Table name: registry_permissions
#
#  id               :integer          not null, primary key
#  kind             :string
#  project_id       :integer
#  registry_user_id :integer
#
# Indexes
#
#  index_registry_permissions_on_project_id        (project_id)
#  index_registry_permissions_on_registry_user_id  (registry_user_id)
#
class RegistryPermission < ApplicationRecord
  belongs_to :registry_user
  belongs_to :project
end
