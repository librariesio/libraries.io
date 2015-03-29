class User < ActiveRecord::Base
  has_many :subscriptions
  has_many :manifests
  has_many :api_keys

  def admin?
    ['andrew', 'barisbalic', 'malditogeek', 'olizilla', 'thattommyhall', 'zachinglis'].include?(nickname)
  end

  def github_client
    Octokit::Client.new(access_token: token, auto_paginate: true)
  end

  def has_repo_scope?
    github_client.scopes.include? 'repo'
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
