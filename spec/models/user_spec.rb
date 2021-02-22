# frozen_string_literal: true
require 'rails_helper'

describe User, type: :model do
  it { should have_many(:subscriptions) }
  it { should have_many(:subscribed_projects) }
  it { should have_many(:repository_subscriptions) }
  it { should have_many(:api_keys) }
  it { should have_many(:repository_permissions) }
  it { should have_many(:all_repositories) }
  it { should have_many(:adminable_repository_permissions) }
  it { should have_many(:adminable_repositories) }
  it { should have_many(:adminable_repository_organisations) }
  it { should have_many(:source_repositories) }
  it { should have_many(:watched_repositories) }
  it { should have_many(:dependencies) }
  it { should have_many(:really_all_dependencies) }
  it { should have_many(:all_dependent_projects) }
  it { should have_many(:favourite_projects) }
  it { should have_many(:project_mutes) }
  it { should have_many(:muted_projects) }
  it { should have_many(:project_suggestions) }

  it { should validate_presence_of(:email).on(:update) }
end
