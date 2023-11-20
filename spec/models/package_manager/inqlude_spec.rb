# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Inqlude do
  let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

  it 'has formatted name of "Inqlude"' do
    expect(described_class.formatted_name).to eq("Inqlude")
  end

  describe "#package_link" do
    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://inqlude.org/libraries/foo.html")
    end

    it "ignores version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://inqlude.org/libraries/foo.html")
    end
  end

  describe "#install_instructions" do
    it "returns a command to install the project" do
      expect(described_class.install_instructions(project)).to eq("inqlude install foo")
    end

    it "ignores version" do
      expect(described_class.install_instructions(project, "2.0.0")).to eq("inqlude install foo")
    end
  end
end
