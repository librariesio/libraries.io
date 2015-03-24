class User < ActiveRecord::Base
  has_many :subscriptions
  has_many :manifests
  has_many :api_keys

  def admin?
    ['andrew'].include?(nickname)
  end

  def self.create_from_auth_hash(hash)
    create!(AuthHash.new(hash).user_info)
  end

  def assign_from_auth_hash(hash)
    update_attributes(AuthHash.new(hash).user_info)
  end

  def self.find_by_auth_hash(hash)
    conditions = AuthHash.new(hash).user_info.slice(:provider, :uid)
    where(conditions).first
  end

  def subscribed_to?(project)
    subscriptions.find_by_project_id(project.id)
  end
end
