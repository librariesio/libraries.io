require 'rails_helper'

describe RepositoryOrganisation, type: :model do
  it { should have_many(:repositories) }
  it { should have_many(:source_repositories) }
  it { should have_many(:open_source_repositories) }
  it { should have_many(:dependencies) }
  it { should have_many(:favourite_projects) }
  it { should have_many(:contributors) }
  it { should have_many(:projects) }

  it { should validate_presence_of(:uuid) }
  it { should validate_uniqueness_of(:uuid).scoped_to(:host_type) }
end
