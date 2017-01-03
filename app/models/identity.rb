class Identity < ApplicationRecord
  belongs_to :user
  validates_presence_of :uid, :provider

  def self.find_with_omniauth(auth)
    find_by(uid: auth['uid'], provider: auth['provider'])
  end

  def self.create_with_omniauth(auth)
    create(uid: auth['uid'], provider: auth['provider'])
  end

  def find_existing_user
    return nil unless provider =~ /github/
    User.find_by_uid(uid)
  end

  def update_from_auth_hash(auth)
    # save extra fields from auth hash
  end
end
