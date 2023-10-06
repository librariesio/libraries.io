# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Base::ApiVersion do
  describe "#to_version_model_attributes" do
    let(:api_version_to_upsert) do
      described_class.new(
        version_number: "1.0.0",
        published_at: nil,
        runtime_dependencies_count: nil,
        original_license: nil,
        repository_sources: nil,
        status: nil
      )
    end

    it "removes keys it doesn't have a value for except for status" do
      expect(api_version_to_upsert.to_version_model_attributes).to eq({
                                                                        number: "1.0.0",
                                                                        status: nil,
                                                                      })
    end
  end
end
