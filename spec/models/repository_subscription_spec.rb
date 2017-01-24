require 'rails_helper'

describe RepositorySubscription, type: :model do
  it { should belong_to(:user) }
  it { should have_many(:subscriptions) }
  it { should belong_to(:repository).with_foreign_key('github_repository_id') }
end
