class RegistryPermission < ApplicationRecord
  belongs_to :registry_user
  belongs_to :project
end
