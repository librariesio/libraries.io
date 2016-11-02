require 'rails_helper'

describe GithubTag do
  it { should belong_to(:github_repository) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:sha) }
  it { should validate_presence_of(:github_repository) }
end
