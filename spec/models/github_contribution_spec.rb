require 'rails_helper'

describe GithubContribution, type: :model do
  it { should belong_to(:github_user) }
  it { should belong_to(:repository).with_foreign_key('github_repository_id') }
end
