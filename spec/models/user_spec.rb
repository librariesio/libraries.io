
# has_one :github_user, primary_key: :uid, foreign_key: :github_id
require 'rails_helper'

describe User do
  it { should have_many(:subscriptions) }
  it { should have_many(:subscribed_projects) }
  it { should have_many(:repository_subscriptions) }
  it { should have_many(:api_keys) }
  it { should have_many(:repository_permissions) }
  it { should have_many(:all_github_repositories) }
  it { should have_many(:adminable_repository_permissions) }
  it { should have_many(:adminable_github_repositories) }
  it { should have_many(:adminable_github_orgs) }
  it { should have_many(:github_repositories) }
  it { should have_many(:source_github_repositories) }
  it { should have_many(:watched_github_repositories) }
  it { should have_many(:watched_dependencies) }
  it { should have_many(:watched_dependent_projects) }
  it { should have_many(:dependencies) }
  it { should have_many(:all_dependencies) }
  it { should have_many(:really_all_dependencies) }
  it { should have_many(:all_dependent_projects) }
  it { should have_many(:favourite_projects) }
  it { should have_many(:project_mutes) }
  it { should have_many(:muted_projects) }
  it { should have_many(:payola_subscriptions) }
  it { should have_many(:project_suggestions) }

  it { should have_one(:github_user) }

  it { should validate_presence_of(:email).on(:update) }
end
