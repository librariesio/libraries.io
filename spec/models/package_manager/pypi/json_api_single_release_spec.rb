# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Pypi::JsonApiSingleRelease do
  describe "#license" do
    let(:release) { described_class.new(data: data) }
    let(:data) { { "info" => { "license" => license } } }
    let(:license) { "MIT" }

    it "finds the license in the data" do
      expect(release.license).to eq(license)
    end
  end
end
