# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Rubygems do
  let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

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
      expect(described_class.download_url(project, "1.0.0")).to eq("https://rubygems.org/downloads/foo-1.0.0.gem")
    end
  end

  describe "#documentation_url" do
    it "returns a link to project website" do
      expect(described_class.documentation_url(project)).to eq("http://www.rubydoc.info/gems/foo/")
    end

    it "handles version" do
      expect(described_class.documentation_url(project, "2.0.0")).to eq("http://www.rubydoc.info/gems/foo/2.0.0")
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

  describe "#deprecate_versions" do   
    before do
      project.versions.create!(number: "1.0.0")
      project.versions.create!(number: "1.0.1")
    end

    it "should mark missing versions as Removed" do
      described_class.deprecate_versions(project, [{ number: "1.0.0", published_at: nil, original_license: nil }])
      expect(project.reload.versions.pluck(:number, :status)).to match_array([["1.0.0", nil], ["1.0.1", "Removed"]])
    end
  end
end
