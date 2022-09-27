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

  it "should delay version requested if version didn't get created" do
    expect(PackageManagerDownloadWorker).to receive(:perform_in).with(5.seconds, "go", "github.com/hi/ima.package", "1.2.3", "unknown", 1)
    expect(PackageManager::Go).to receive(:update).with("github.com/hi/ima.package", sync_version: "1.2.3")
    expect(Rails.logger).to receive(:info).with("[Version Update Failure] platform=go name=github.com/hi/ima.package version=1.2.3")

    subject.perform("go", "github.com/hi/ima.package", "1.2.3")
  end

  it "should raise an error if version didn't get created after 30 attempts" do
    expect(PackageManagerDownloadWorker).to_not receive(:perform_in)
    expect(PackageManager::Go).to receive(:update).with("github.com/hi/ima.package", sync_version: "1.2.3")
    expect(Rails.logger).to receive(:info).with("[Version Update Failure] platform=go name=github.com/hi/ima.package version=1.2.3")

    expect { subject.perform("go", "github.com/hi/ima.package", "1.2.3", nil, 21) }.to raise_exception(PackageManagerDownloadWorker::VersionUpdateFailure)
  end
end
