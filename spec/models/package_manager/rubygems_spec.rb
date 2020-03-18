# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Rubygems do
  let(:project) { create(:project, name: "foo", platform: described_class.name) }

  it 'has formatted name of "Rubygems"' do
    expect(described_class.formatted_name).to eq("Rubygems")
  end

  describe "#package_link" do
    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://rubygems.org/gems/foo")
    end

    it "handles version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://rubygems.org/gems/foo/versions/2.0.0")
    end
  end

  describe "download_url" do
    it "returns a link to project tarball" do
      expect(described_class.download_url("foo", "1.0.0")).to eq("https://rubygems.org/downloads/foo-1.0.0.gem")
    end
  end

  describe "#documentation_url" do
    it "returns a link to project website" do
      expect(described_class.documentation_url("foo")).to eq("http://www.rubydoc.info/gems/foo/")
    end

    it "handles version" do
      expect(described_class.documentation_url("foo", "2.0.0")).to eq("http://www.rubydoc.info/gems/foo/2.0.0")
    end
  end

  describe "#install_instructions" do
    it "returns a command to install the project" do
      expect(described_class.install_instructions(project)).to eq("gem install foo")
    end

    it "handles version" do
      expect(described_class.install_instructions(project, "2.0.0")).to eq("gem install foo -v 2.0.0")
    end
  end
end
