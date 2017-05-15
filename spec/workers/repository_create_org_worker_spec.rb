require 'rails_helper'

describe RepositoryCreateOrgWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :owners
  end

  it "should create from github" do
    org_login = 'rails'
    expect(RepositoryOwner::Base).to receive(:download_org_from_host).with('GitHub', org_login)
    subject.perform(org_login)
  end
end
