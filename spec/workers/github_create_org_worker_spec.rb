require 'rails_helper'

describe GithubCreateOrgWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :owners
  end

  it "should create from github" do
    org_login = 'rails'
    expect(GithubOrganisation).to receive(:create_from_github).with(org_login)
    subject.perform(org_login)
  end
end
