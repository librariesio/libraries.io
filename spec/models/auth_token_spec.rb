require 'rails_helper'

describe AuthToken, type: :model do
  it { should validate_presence_of(:token) }
end
