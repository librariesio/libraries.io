# frozen_string_literal: true

require "rails_helper"

describe PackageManagerDownloadWorker do
  it "should use the critical priority queue" do
    is_expected.to be_processed_in :critical
  end

  it "should sync all versions if none are specified" do
    expect(PackageManager::Rubygems).to receive(:update).with("rails", sync_version: :all, force_sync_dependencies: false)
    subject.perform("PackageManager::Rubygems", "rails")
  end

  it "should raise an error with an unkown package manager" do
    expect { subject.perform("what", "isthis") }.to raise_exception(StandardError, "Platform 'what' not found")
  end

  it "should delay version requested if version didn't get created" do
    expect(PackageManagerDownloadWorker).to receive(:perform_in).with(5.seconds, "go", "github.com/hi/ima.package", "1.2.3", "unknown", 1, false)
    expect(PackageManager::Go).to receive(:update).with("github.com/hi/ima.package", sync_version: "1.2.3", force_sync_dependencies: false)
    expect(Rails.logger).to receive(:info).with(a_string_matching("Package update"))
    expect(Rails.logger).to receive(:info).with("[Version Update Failure] platform=go name=github.com/hi/ima.package version=1.2.3")

    subject.perform("go", "github.com/hi/ima.package", "1.2.3")
  end

  it "should skip if platform syncing not active" do
    an_inactive_platform = PackageManager::Maven::Atlassian
    expect(an_inactive_platform::SYNC_ACTIVE).to_not eq(true)
    expect(an_inactive_platform).to_not receive(:update)
    expect(PackageManagerDownloadWorker).to_not receive(:perform_in)
    expect(Rails.logger).to receive(:info).with(a_string_matching("Skipping"))

    subject.perform("maven_atlassian", "github.com/hi/ima.package", "1.2.3")
  end

  context "when the package manager supports single versions updates" do
    # remove the stub once the NPM::SUPPORTS_SINGLE_VERSION_UPDATE gets sets back to true
    before do
      stub_const("PackageManager::NPM::SUPPORTS_SINGLE_VERSION_UPDATE", true)
    end

    it "should raise an error if version didn't get created after 15 attempts" do
      expect(PackageManagerDownloadWorker).to_not receive(:perform_in)
      expect(PackageManager::NPM).to receive(:update).with("a-package", sync_version: "1.2.3", force_sync_dependencies: false)
      expect(Rails.logger).to receive(:info).with(a_string_matching("Package update"))
      expect(Rails.logger).to receive(:info).with("[Version Update Failure] platform=npm name=a-package version=1.2.3")

      expect { subject.perform("npm", "a-package", "1.2.3", nil, 16) }.to raise_exception(PackageManagerDownloadWorker::VersionUpdateFailure)
    end
  end

  it "should not raise an error if version didn't get created after 15 attempts and is golang" do
    expect(PackageManagerDownloadWorker).to_not receive(:perform_in)
    expect(PackageManager::Go).to receive(:update).with("github.com/hi/ima.package", sync_version: "1.2.3", force_sync_dependencies: false)
    expect(Rails.logger).to receive(:info).with(a_string_matching("Package update"))
    expect(Rails.logger).to receive(:info).with("[Version Update Failure] platform=go name=github.com/hi/ima.package version=1.2.3")

    expect { subject.perform("go", "github.com/hi/ima.package", "1.2.3", nil, 16) }.to_not raise_exception
  end
end
