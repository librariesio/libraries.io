# frozen_string_literal: true

require "rails_helper"

describe PackageManagerDownloadWorker do
  it "should use the critical priority queue" do
    is_expected.to be_processed_in :critical
  end

  it "should sync an org" do
    class_name = PackageManager::Rubygems.name
    name = "rails"
    expect(PackageManager::Rubygems).to receive(:update).with(name)
    subject.perform(class_name, name)
  end
end
