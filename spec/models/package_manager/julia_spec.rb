# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Julia do
  it 'has formatted name of "Julia"' do
    expect(described_class.formatted_name).to eq("Julia")
  end

  describe "#package_link" do
    let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("http://pkg.julialang.org/?pkg=foo&ver=release")
    end

    it "ignores version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("http://pkg.julialang.org/?pkg=foo&ver=release")
    end
  end

  describe ".project" do
    it "does not shell out or touch the filesystem for names with shell metacharacters" do
      expect(described_class).not_to receive(:`)
      expect(File).not_to receive(:read)

      ["foo;touch /tmp/pwned", "foo$(id)", "../etc", "foo bar", "", ".hidden"].each do |name|
        expect(described_class.project(name)).to be_nil
      end
    end
  end
end
