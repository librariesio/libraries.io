require 'rails_helper'

describe Project, :vcr, type: :model do
  it { should have_many(:versions) }
  it { should have_many(:dependencies) }
  it { should have_many(:github_contributions) }
  it { should have_many(:contributors) }
  it { should have_many(:github_tags) }
  it { should have_many(:dependents) }
  it { should have_many(:repository_dependencies) }
  it { should have_many(:dependent_manifests) }
  it { should have_many(:dependent_repositories) }
  it { should have_many(:subscriptions) }
  it { should have_many(:project_suggestions) }
  it { should have_one(:readme) }
  it { should belong_to(:repository).with_foreign_key('github_repository_id') }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:platform) }
end
