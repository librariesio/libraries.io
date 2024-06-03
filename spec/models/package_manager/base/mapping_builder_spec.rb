# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Base::MappingBuilder do
  context ".build_hash" do
    it "requires name, description, and repository_url" do
      expect { described_class.build_hash }
        .to raise_exception(ArgumentError, "missing keywords: :name, :description, :repository_url")
    end

    it "raises an error on disallowed keywords" do
      expect do
        described_class.build_hash(
          name: "a-name",
          description: "a-description",
          repository_url: "a-repository-url",
          foo: "bar"
        )
      end.to raise_exception(ArgumentError, "unknown keyword: :foo")
    end

    it "returns a Hash containing the params that were passed" do
      hash = described_class.build_hash(
        name: "a-name",
        description: "a-description",
        repository_url: "a-repository-url",
        homepage: "homepage",
        keywords_array: "keywords-array",
        licenses: ["licenses"],
        versions: ["a-version"]
      )

      expect(hash[:name]).to eq("a-name")
      expect(hash[:description]).to eq("a-description")
      expect(hash[:repository_url]).to eq("a-repository-url")
      expect(hash[:homepage]).to eq("homepage")
      expect(hash[:keywords_array]).to eq("keywords-array")
      expect(hash[:licenses]).to eq(["licenses"])
      expect(hash[:versions]).to eq(["a-version"])
    end
  end
end
