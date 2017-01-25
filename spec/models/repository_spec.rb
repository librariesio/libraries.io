require 'rails_helper'

describe Repository, :vcr, type: :model do
  it { should have_many(:projects) }
  it { should have_many(:contributions) }
  it { should have_many(:contributors) }
  it { should have_many(:tags) }
  it { should have_many(:published_tags) }
  it { should have_many(:manifests) }
  it { should have_many(:dependencies) }
  it { should have_many(:forked_repositories) }
  it { should have_many(:repository_subscriptions) }
  it { should have_many(:web_hooks) }
  it { should have_many(:issues) }
  it { should have_one(:readme) }
  it { should belong_to(:github_organisation) }
  it { should belong_to(:github_user) }
  it { should belong_to(:source) }

  it { should validate_uniqueness_of(:full_name) }
  it { should validate_uniqueness_of(:github_id) }
end
