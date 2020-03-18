# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Meteor do
  let(:project) { create(:project, name: "foo:bar", platform: described_class.name) }

  it 'has formatted name of "Meteor"' do
    expect(described_class.formatted_name).to eq("Meteor")
  end

  describe "#package_link" do
    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://atmospherejs.com/foo/bar")
    end

    it "ignores version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://atmospherejs.com/foo/bar")
    end
  end

  describe "#install_instructions" do
    it "returns a command to install the project" do
      expect(described_class.install_instructions(project)).to eq("meteor add foo:bar")
    end

    it "handles version" do
      expect(described_class.install_instructions(project, "2.0.0")).to eq("meteor add foo:bar@=2.0.0")
    end
  end
end
