# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Cargo do
  it 'has formatted name of "Cargo"' do
    expect(described_class.formatted_name).to eq("Cargo")
  end

  describe "#package_link" do
    let(:project) { create(:project, name: "foo", platform: described_class.name) }

    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://crates.io/crates/foo/")
    end

    it "handles version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://crates.io/crates/foo/2.0.0")
    end
  end

  describe "#download_url" do
    it "returns a link to project tarball" do
      expect(described_class.download_url("foo", "1.0.0")).to eq("https://crates.io/api/v1/crates/foo/1.0.0/download")
    end
  end

  describe "#documentation_url" do
    it "returns a link to project website" do
      expect(described_class.documentation_url("foo")).to eq("https://docs.rs/foo/")
    end

    it "handles version" do
      expect(described_class.documentation_url("foo", "2.0.0")).to eq("https://docs.rs/foo/2.0.0")
    end
  end
end
