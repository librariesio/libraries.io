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
end
