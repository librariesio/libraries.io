# frozen_string_literal: true

require "rails_helper"

describe RepositoryCreateUserWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :owners
  end

  it "should create from github" do
    org_login = "andrew"
    host_type = "GitHub"
    expect(RepositoryOwner::Base).to receive(:download_user_from_host).with(host_type, org_login)
    subject.perform(host_type, org_login)
  end
end
