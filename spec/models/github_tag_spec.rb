require 'rails_helper'

describe GithubTag, type: :model do
  it { should belong_to(:github_repository) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:sha) }
  it { should validate_presence_of(:github_repository) }
  it { should validate_uniqueness_of(:name).scoped_to(:github_repository_id) }
end
