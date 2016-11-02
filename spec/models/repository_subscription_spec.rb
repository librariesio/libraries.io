require 'rails_helper'

describe RepositorySubscription do
  it { should belong_to(:user) }
  it { should have_many(:subscriptions) }
  it { should belong_to(:github_repository) }
end
