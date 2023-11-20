# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Racket do
  let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

  it 'has formatted name of "Racket"' do
    expect(described_class.formatted_name).to eq("Racket")
  end

  describe "#package_link" do
    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("http://pkgs.racket-lang.org/package/foo")
    end
  end
end
