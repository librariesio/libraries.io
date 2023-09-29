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

  describe "#<=>" do
    let(:left_release) { described_class.new(version_number: "1.0.0", published_at: published_at_left, is_yanked: false, yanked_reason: nil) }
    let(:right_release) { described_class.new(version_number: "1.0.1", published_at: published_at_right, is_yanked: false, yanked_reason: nil) }

    let(:published_at_left) { 1.month.ago }
    let(:published_at_right) { 1.day.ago }

    context "with both releases having published at dates" do
      it "sorts correctly" do
        expect([left_release, right_release].sort).to eq([left_release, right_release])
      end
    end

    context "with left release not having published at date" do
      let(:published_at_left) { nil }

      it "sorts the empty item first" do
        expect([left_release, right_release].sort).to eq([left_release, right_release])
      end
    end

    context "with right release not having published at date" do
      let(:published_at_right) { nil }

      it "sorts the empty item first" do
        expect([left_release, right_release].sort).to eq([right_release, left_release])
      end
    end
  end
end
