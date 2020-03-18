# frozen_string_literal: true

require "rails_helper"

describe PackageManager::CPAN do
  it 'has formatted name of "CPAN"' do
    expect(described_class.formatted_name).to eq("CPAN")
  end

  describe "#package_link" do
    let(:project) { create(:project, name: "foo", platform: described_class.name) }

    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://metacpan.org/release/foo")
    end

    it "ignores version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://metacpan.org/release/foo")
    end
  end
end
