require "rails_helper"

describe PackageManager::Base::VersionUpdater do
  describe "#execute" do
    let(:db_project) { Project.create(platform: "Pypi", name: project_name) }
    let!(:db_project_version) { db_project.versions.create(number: version_number, published_at: nil, repository_sources: ["a"]) }
    let(:incoming_version) { instance_double(PackageManager::Base::IncomingVersion, number: version_number, to_h: { published_at: published_at }) }

    let(:project_name) { "name" }
    let(:version_number) { "1.0.0" }
    let(:published_at) { Time.zone.now }

    let(:version_updater) { described_class.new(project: db_project, incoming_version: incoming_version, repository_source: "b") }

    it "updates the version" do
      version_updater.execute

      db_project_version.reload

      # deal with microtime
      expect(db_project_version.published_at).to be_within(1.second).of(published_at)
      expect(db_project_version.repository_sources).to eq(%w[a b])
    end
  end
end
