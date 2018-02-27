class RegistryUser < ApplicationRecord
  has_many :registry_permissions
  has_many :projects, through: :registry_permissions
end
