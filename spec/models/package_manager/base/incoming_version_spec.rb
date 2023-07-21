require "rails_helper"

describe PackageManager::Base::IncomingVersion do
  describe "#to_h" do
    let(:incoming_version) do
      described_class.new(
        number: "1.0.0",
        published_at: nil,
        runtime_dependencies_count: nil,
        original_license: nil,
        repository_sources: nil,
        status: nil
      )
    end

    it "removes keys it doesn't have a value for" do
      expect(incoming_version.to_h).to eq({ number: "1.0.0" })
    end
  end
end
