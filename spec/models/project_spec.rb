require 'rails_helper'

describe Project, type: :model do
  it { should have_many(:versions) }
  it { should have_many(:dependencies) }
  it { should have_many(:contributions) }
  it { should have_many(:contributors) }
  it { should have_many(:tags) }
  it { should have_many(:dependents) }
  it { should have_many(:repository_dependencies) }
  it { should have_many(:dependent_manifests) }
  it { should have_many(:dependent_repositories) }
  it { should have_many(:subscriptions) }
  it { should have_many(:project_suggestions) }
  it { should have_one(:readme) }
  it { should belong_to(:repository) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:platform) }

  context 'rails 5.1 upgrade' do

    let(:repository) { create(:repository) }
    let!(:tag) { create(:tag, repository: repository)}
    let(:project) { create(:project, repository: repository) }

    it "shouldn't error finding tags for projects" do
      expect(project.tags).to eq([tag])
    end

  end
end
