# frozen_string_literal: true

require "rails_helper"

describe PackageManagerDownloadWorker do
  it "should use the critical priority queue" do
    is_expected.to be_processed_in :critical
  end

  it "should sync all versions if none are specified" do
    expect(PackageManager::Rubygems).to receive(:update).with("rails", sync_version: :all)
    subject.perform("PackageManager::Rubygems", "rails")
  end

  it "should raise an error with an unkown package manager" do
    expect { subject.perform("what", "isthis") }.to raise_exception(StandardError, "Platform 'what' not found")
  end

  it "should raise an error if version requested didn't get created" do
    expect(PackageManager::Go).to receive(:update).with("github.com/hi/ima.package", sync_version: "1.2.3")

    expected_msg = "PackageManagerDownloadWorker version update fail platform=go name=github.com/hi/ima.package version=1.2.3"
    expect { subject.perform("go", "github.com/hi/ima.package", "1.2.3") }.to raise_exception(StandardError, expected_msg)
  end
end
