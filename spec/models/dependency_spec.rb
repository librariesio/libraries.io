require 'rails_helper'

describe Dependency, type: :model do
  it { should belong_to(:version) }
  it { should belong_to(:project) }

  it { should validate_presence_of(:project_name) }
  it { should validate_presence_of(:version_id) }
  it { should validate_presence_of(:requirements) }
  it { should validate_presence_of(:platform) }

  context "a dependency" do
    subject { create(:dependency, version_project: nil) }

    it "should set version_project_id before create" do
      expect(subject.version_project).to eq(subject.version.project)
    end
  end
end
