# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Cargo do
  let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

  it 'has formatted name of "Cargo"' do
    expect(described_class.formatted_name).to eq("Cargo")
  end

  describe "#package_link" do
    let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://crates.io/crates/foo/")
    end

    it "handles version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://crates.io/crates/foo/2.0.0")
    end
  end

  describe "#download_url" do
    it "returns a link to project tarball" do
      expect(described_class.download_url(project, "1.0.0")).to eq("https://crates.io/api/v1/crates/foo/1.0.0/download")
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

  describe "::deprecation_info" do
    subject(:deprecation) { described_class.deprecation_info(project) }

    context "when not deprecated" do
      let(:project) { create(:project, name: "libc", platform: described_class.formatted_name) }

      it "is false" do
        VCR.use_cassette("cargo/pkg") do
          expect(deprecation[:is_deprecated]).to eq(false)
          expect(deprecation[:message]).to eq(nil)
        end
      end
    end

    context "when marked deprecated with cargo.toml badge" do
      let(:project) { create(:project, name: "cld2", platform: described_class.formatted_name) }

      it "returns deprecation info" do
        VCR.use_cassette("cargo/pkg_toml_deprecated") do
          expect(deprecation[:is_deprecated]).to eq(true)
          expect(deprecation[:message]).to a_string_including("Cargo.toml")
        end
      end
    end

    context "when tagged with keyword `deprecated`" do
      let(:project) { create(:project, name: "substrate-subxt", platform: described_class.formatted_name) }

      it "returns deprecation info" do
        VCR.use_cassette("cargo/pkg_keyword_deprecated") do
          expect(deprecation[:is_deprecated]).to eq(true)
          expect(deprecation[:message]).to a_string_including("keyword")
        end
      end
    end
  end
end
