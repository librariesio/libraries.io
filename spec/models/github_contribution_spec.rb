require 'rails_helper'

describe GithubContribution do
  it { should belong_to(:github_user) }
  it { should belong_to(:github_repository) }
end
