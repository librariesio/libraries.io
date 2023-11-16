# frozen_string_literal: true

require "rails_helper"

describe Version, type: :model do
  it { should belong_to(:project) }
  it { should have_many(:dependencies) }
  it { should have_many(:runtime_dependencies).conditions(kind: %w[runtime normal]) }

  it { should validate_presence_of(:project_id) }
  it { should validate_presence_of(:number) }

  context "spdx expressions" do
    let(:project) { create(:project) }
    it "updates spdx expressions on save" do
      version = Version.create(project: project, original_license: "MIT", number: "1.0.0")
      version.save
      expect(version.spdx_expression).to eq "MIT"
    end

    it "sets spdx expression to NONE when there is no license set" do
      version = Version.create(project: project, original_license: "", number: "1.0.0")
      version.save
      expect(version.spdx_expression).to eq "NONE"
    end

    it "sets spdx expression to NOASSERTION when the license is something we don't understand" do
      version = Version.create(project: project, original_license: "some fake license", number: "1.0.0")
      version.save
      expect(version.spdx_expression).to eq "NOASSERTION"
    end
  end

  context "with dependencies" do
    let(:version) { create(:version) }

    before do
      create(:dependency, version: version, requirements: "> 0", kind: "runtime")
      create(:dependency, version: version, requirements: "> 0", kind: "test")
    end

    it "can update its dependencies_count" do
      expect { version.set_dependencies_count }.to change { version.dependencies_count }.to(2)
    end

    it "can update its runtime_dependencies_count" do
      expect { version.set_runtime_dependencies_count }.to change { version.runtime_dependencies_count }.to(1)
    end
  end
end
