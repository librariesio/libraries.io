# frozen_string_literal: true

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
