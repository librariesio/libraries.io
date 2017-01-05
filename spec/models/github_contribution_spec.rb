require 'rails_helper'

describe GithubContribution, type: :model do
  it { should belong_to(:github_user) }
  it { should belong_to(:github_repository) }
end
