require "rails_helper"

describe PackageManager::Pypi::JsonApiProjectReleases do
  describe "#all_releases_have_published_at?" do
    let(:project_releases) do
      described_class.new([release1, release2])
    end

    let(:release1) { PackageManager::Pypi::JsonApiProjectRelease.new(version_number: "1.0.0", published_at: Time.now, is_yanked: false, yanked_reason: nil) }
    let(:release2) { PackageManager::Pypi::JsonApiProjectRelease.new(version_number: "2.0.0", published_at: release2_published_at, is_yanked: false, yanked_reason: nil) }

    let(:release2_published_at) { Time.now }

    context "all do" do
      it "returns true" do
        expect(project_releases.all_releases_have_published_at?).to eq(true)
      end
    end

    context "one does not" do
      let(:release2_published_at) { nil }

      it "returns false" do
        expect(project_releases.all_releases_have_published_at?).to eq(false)
      end
    end
  end
end
