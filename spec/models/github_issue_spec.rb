require 'rails_helper'

describe GithubIssue, type: :model do
  it { should belong_to(:repository).with_foreign_key('github_repository_id') }
  it { should belong_to(:github_user) }
end
