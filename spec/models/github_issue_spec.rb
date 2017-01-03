require 'rails_helper'

describe GithubIssue, type: :model do
  it { should belong_to(:github_repository) }
  it { should belong_to(:github_user) }
end
