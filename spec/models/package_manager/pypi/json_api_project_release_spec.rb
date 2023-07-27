# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Pypi::JsonApiProjectRelease do
  describe "#published_at?" do
    let(:release) { described_class.new(version_number: "1.0.0", published_at: published_at, is_yanked: false, yanked_reason: nil) }
    let(:published_at) { nil }

    context "with nil published_at" do
      it "returns false" do
        expect(release.published_at?).to eq(false)
      end
    end

    context "with non-nil published_at" do
      let(:published_at) { "whatever" }

      it "returns true" do
        expect(release.published_at?).to eq(true)
      end
    end
  end
end
