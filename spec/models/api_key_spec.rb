# frozen_string_literal: true

require "rails_helper"

describe ApiKey, type: :model do
  it { should belong_to(:user) }
end
