# frozen_string_literal: true

# == Schema Information
#
# Table name: deleted_projects
#
#  id         :bigint           not null, primary key
#  digest     :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_deleted_projects_on_digest      (digest) UNIQUE
#  index_deleted_projects_on_updated_at  (updated_at)
#
class DeletedProject < ApplicationRecord
  scope :updated_within, ->(start, stop) { where("updated_at >= ? and updated_at <= ? ", start, stop).order(updated_at: :asc) }

  def self.digest_from_platform_and_name(platform, name)
    sha1 = Digest::SHA256.new
    # the .lowercase ensures it's easy for everyone to get the digest right
    sha1.update(platform.downcase)
    # package names are case-sensitive though, so no lowercase here
    sha1.update(name)
    sha1.hexdigest
  end

  def self.create_from_platform_and_name!(platform, name)
    DeletedProject.create!(digest: digest_from_platform_and_name(platform, name))
  end
end
