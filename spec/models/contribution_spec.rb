require 'rails_helper'

describe Contribution, type: :model do
  it { should belong_to(:github_user) }
  it { should belong_to(:repository) }
end
