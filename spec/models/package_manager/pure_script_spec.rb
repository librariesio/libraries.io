# frozen_string_literal: true

require "rails_helper"

describe PackageManager::PureScript do
  let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

  it 'has formatted name of "PureScript"' do
    expect(described_class.formatted_name).to eq("PureScript")
  end

  describe "#install_instructions" do
    it "returns a command to install the project" do
      expect(described_class.install_instructions(project)).to eq("psc-package install foo")
    end

    it "ignores version" do
      expect(described_class.install_instructions(project, "2.0.0")).to eq("psc-package install foo")
    end
  end
end
