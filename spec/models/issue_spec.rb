require 'rails_helper'

describe Issue, type: :model do
  it { should belong_to(:repository) }
  it { should belong_to(:github_user) }
end
