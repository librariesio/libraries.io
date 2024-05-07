# frozen_string_literal: true

require "rails_helper"

describe RepositoryOwner::Base do
  context ".sanitized_hash_with_indifferent_access_from_client_response" do
    let(:hash) do
      {
        "id" => 1234,
        "name" => "My \u0000Name With\u0000 Null Bytes",
        "company" => "My \u0000Company",
      }
    end
    let(:result) { RepositoryOwner::Base.sanitized_hash_with_indifferent_access_from_client_response(hash) }

    it "should return a HashWithIndifferentAccess" do
      expect(result).to be_a(HashWithIndifferentAccess)
      expect(result[:id]).to eq 1234
      expect(result["id"]).to eq 1234
    end

    it "should strip null bytes" do
      expect(result["name"]).to eq("My Name With Null Bytes")
      expect(result["company"]).to eq("My Company")
    end
  end
end
