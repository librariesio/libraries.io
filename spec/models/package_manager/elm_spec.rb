# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Elm do
  let(:project) { create(:project, name: "foo", platform: described_class.name) }

  it 'has formatted name of "Elm"' do
    expect(described_class.formatted_name).to eq("Elm")
  end

  describe "#package_link" do
    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("http://package.elm-lang.org/packages/foo/latest")
    end

    it "handles version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("http://package.elm-lang.org/packages/foo/2.0.0")
    end
  end

  describe "download_url" do
    it "returns a link to project tarball" do
      expect(described_class.download_url("foo/bar", "1.0.0")).to eq("https://github.com/foo/bar/archive/1.0.0.zip")
    end
  end

  describe "#install_instructions" do
    it "returns a command to install the project" do
      expect(described_class.install_instructions(project)).to eq("elm-package install foo ")
    end

    it "handles version" do
      expect(described_class.install_instructions(project, "2.0.0")).to eq("elm-package install foo 2.0.0")
    end
  end
end
