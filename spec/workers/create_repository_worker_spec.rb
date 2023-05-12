# frozen_string_literal: true

require "rails_helper"

describe CreateRepositoryWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :repo
  end

  it "should create from github" do
    repo_name = "rails/rails"
    expect(Repository).to receive(:create_from_host).with("GitHub", repo_name, nil)
    subject.perform("GitHub", repo_name)
  end
end
