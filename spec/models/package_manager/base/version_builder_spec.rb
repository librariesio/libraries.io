# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Base::VersionBuilder do
  context ".build_hash" do
    it "requires number" do
      expect { described_class.build_hash }
        .to raise_exception(ArgumentError, "missing keyword: :number")
    end

    it "raises an error on disallowed keywords" do
      expect do
        described_class.build_hash(
          number: "a-number",
          foo: "bar"
        )
      end.to raise_exception(ArgumentError, "unknown keyword: :foo")
    end

    it "returns a Hash containing the params that were passed" do
      hash = described_class.build_hash(
        number: "a-number",
        status: "a-status",
        created_at: "a-created-at",
        published_at: "a-published-at",
        original_license: "original-license",
        dependencies: [] # this is a one-off for NuGet, see VersionBuilder for details
      )

      expect(hash[:number]).to eq("a-number")
      expect(hash[:status]).to eq("a-status")
      expect(hash[:created_at]).to eq("a-created-at")
      expect(hash[:published_at]).to eq("a-published-at")
      expect(hash[:original_license]).to eq("original-license")
      expect(hash[:dependencies]).to eq([])
    end
  end
end
