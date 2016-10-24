require 'rails_helper'

describe AuthToken do
  it { should validate_presence_of(:token) }
end
