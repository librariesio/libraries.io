# frozen_string_literal: true

# == Schema Information
#
# Table name: api_keys
#
#  id           :integer          not null, primary key
#  access_token :string
#  deleted_at   :datetime
#  is_internal  :boolean          default(FALSE), not null
#  rate_limit   :integer          default(60)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :integer
#
# Indexes
#
#  index_api_keys_on_access_token  (access_token)
#  index_api_keys_on_user_id       (user_id)
#
class ApiKey < ApplicationRecord
  belongs_to :user

  before_create :generate_access_token

  scope :active, -> { where(deleted_at: nil) }

  private

  def generate_access_token
    begin
      self.access_token = SecureRandom.hex
    end while self.class.exists?(access_token: access_token)
  end
end
