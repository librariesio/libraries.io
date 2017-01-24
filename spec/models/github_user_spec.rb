require 'rails_helper'

describe GithubUser, type: :model do
  it { should have_many(:repositories) }
  it { should have_many(:source_repositories) }
  it { should have_many(:open_source_repositories) }
  it { should have_many(:dependencies) }
  it { should have_many(:favourite_projects) }
  it { should have_many(:contributors) }
  it { should have_many(:projects) }
  it { should have_many(:contributed_repositories) }
  it { should have_many(:fellow_contributors) }
  it { should have_many(:github_issues) }
  it { should have_many(:contributions) }

  it { should validate_uniqueness_of(:login) }
  it { should validate_uniqueness_of(:github_id) }
end
