# frozen_string_literal: true

require "rails_helper"

describe PackageManager::NuGet do
  let(:project) { create(:project, name: "foo", platform: described_class.name) }

  it 'has formatted name of "NuGet"' do
    expect(described_class.formatted_name).to eq("NuGet")
  end

  describe "#package_link" do
    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://www.nuget.org/packages/foo/")
    end

    it "handles version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://www.nuget.org/packages/foo/2.0.0")
    end
  end

  describe "download_url" do
    it "returns a link to project tarball" do
      expect(described_class.download_url("foo", "1.0.0")).to eq("https://www.nuget.org/api/v2/package/foo/1.0.0")
    end
  end

  describe "#install_instructions" do
    it "returns a command to install the project" do
      expect(described_class.install_instructions(project)).to eq("Install-Package foo")
    end

    it "handles version" do
      expect(described_class.install_instructions(project, "2.0.0")).to eq("Install-Package foo -Version 2.0.0")
    end
  end
end
