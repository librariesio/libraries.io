require 'rails_helper'

describe GithubIssue do
  it { should belong_to(:github_repository) }
  it { should belong_to(:github_user) }
end
