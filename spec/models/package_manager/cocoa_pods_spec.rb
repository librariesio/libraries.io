# frozen_string_literal: true

require "rails_helper"

describe PackageManager::CocoaPods do
  let(:project) { create(:project, name: "foo", platform: described_class.name) }

  it 'has formatted name of "CocoaPods"' do
    expect(described_class.formatted_name).to eq("CocoaPods")
  end

  describe "#package_link" do
    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("http://cocoapods.org/pods/foo")
    end

    it "ignores version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("http://cocoapods.org/pods/foo")
    end
  end

  describe "#install_instructions" do
    it "returns a command to install the project" do
      expect(described_class.install_instructions(project)).to eq("pod try foo")
    end

    it "ignores version" do
      expect(described_class.install_instructions(project, "2.0.0")).to eq("pod try foo")
    end
  end

  describe "#documentation_url" do
    it "returns a link to project website" do
      expect(described_class.documentation_url("foo")).to eq("http://cocoadocs.org/docsets/foo/")
    end

    it "handles version" do
      expect(described_class.documentation_url("foo", "2.0.0")).to eq("http://cocoadocs.org/docsets/foo/2.0.0")
    end
  end

  describe "#parse_license" do
    it "returns the license when its a string" do
      expect(described_class.parse_license("foobar")).to eq("foobar")
    end

    it "returns the license type when its a hash" do
      expect(described_class.parse_license({ "type" => "foobar" })).to eq("foobar")
    end
  end
end
