require 'rails_helper'

describe Project, type: :model do
  it { should have_many(:versions) }
  it { should have_many(:dependencies) }
  it { should have_many(:contributions) }
  it { should have_many(:contributors) }
  it { should have_many(:tags) }
  it { should have_many(:dependents) }
  it { should have_many(:repository_dependencies) }
  it { should have_many(:dependent_repositories) }
  it { should have_many(:subscriptions) }
  it { should have_many(:project_suggestions) }
  it { should have_one(:readme) }
  it { should belong_to(:repository) }
  it { should have_many(:repository_maintenance_stats)}

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:platform) }

  describe 'license normalization' do
    let(:project) { create(:project, name: 'foo', platform: PackageManager::Rubygems) }

    it 'handles a single license' do
      project.licenses = "mit"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["MIT"])
    end

    it 'handles comma separated license' do
      project.licenses = "mit,isc"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["MIT", "ISC"])
    end

    it 'handles OR separated licenses' do
      project.licenses = "mit OR isc"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["MIT", "ISC"])
    end

    it 'handles or separated licenses' do
      project.licenses = "mit or ISC"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["MIT", "ISC"])
    end

    it 'handles (OR) separated licenses' do
      project.licenses = "(mit OR isc)"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["MIT", "ISC"])
    end

    it 'handles AND separated licenses' do
      project.licenses = "mit AND ISC"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["MIT", "ISC"])
    end

    it 'handles and separated licenses' do
      project.licenses = "mit and ISC"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["MIT", "ISC"])
    end
  end

  describe 'maintenance stats' do
    let!(:repository) { create(:repository) }
    let!(:project) { create(:project, repository: repository) }

    context "without existing stats" do
      it "should be included in no_existing_stats query" do
        results = Project.no_existing_stats.where(id: project.id)
        expect(results.count).to eql 1
      end
    end

    context "with stats" do
      let!(:stat1) { create(:repository_maintenance_stat, repository: repository) }

      it "should not be in no_existing_stats query" do
        results = Project.no_existing_stats.where(id: project.id)
        expect(results.count).to eql 0
      end

      it "should show up in least_recently_updated_stats query" do
        results = Project.least_recently_updated_stats.where(id: project.id)
        # count will return a hash
        # the key is the grouped column which is the project id
        # the value is the count for that project id
        expect(results.count.key? project.id).to be true
        expect(results.count[project.id]).to eql 1
      end
    end

    context "two projects with stats" do
      let!(:stat1) { create(:repository_maintenance_stat, repository: repository) }
      let!(:repository2) { create(:repository, full_name: "octokit/octokit") }
      let!(:project2) { create(:project, repository: repository2) }
      let!(:stat2) { create(:repository_maintenance_stat, repository: repository2) }

      before do
        stat2.update_column(:updated_at, Date.today - 1.month)
      end

      it "should return project with oldest stats first" do
        results = Project.least_recently_updated_stats
        expect(results.first.id).to eql project2.id
      end

      it "should return both projects" do
        results = Project.least_recently_updated_stats
        expect(results.length).to eql 2
      end

      it "no_existing_stats query should be empty" do
        results = Project.no_existing_stats
        expect(results.length).to eql 0
      end
    end
  end
end
