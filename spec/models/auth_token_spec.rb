# frozen_string_literal: true

require "rails_helper"

describe AuthToken, type: :model do
  it { should validate_presence_of(:token) }

  describe "::new_v4_client" do
    let(:token_value) { Faker::Alphanumeric.alpha }
    subject(:v4_client) { described_class.new_v4_client(token_value) }

    def get_headers_from_client(graphql_client)
      graphql_client.execute.headers(nil)
    end

    it "applies given token to client headers" do
      expect(token_value).to be_present
      expect(get_headers_from_client(v4_client)).to eq({ "Authorization" => "bearer #{token_value}" })
    end
  end

  describe "#safe_to_use?" do
    subject(:auth_token) { described_class.new(token: token_value) }
    let(:token_value) { "" }

    context "when token fails to authenticate" do
      let(:token_value) { "foo" }

      it "returns false" do
        expect(auth_token.safe_to_use?(:v3)).to eq(false)
        expect(auth_token.safe_to_use?(:v4)).to eq(false)
      end
    end

    context "when resource_limits aren't found" do
      before do
        allow(auth_token).to receive(:fetch_resource_limits).and_return({ v3: nil })
      end

      it "returns false" do
        expect(auth_token.safe_to_use?(:v3)).to eq(false)
        expect(auth_token.safe_to_use?(:v4)).to eq(false)
      end
    end

    it "checks the appropriate api limits" do
      allow(auth_token).to receive(:fetch_resource_limits).and_return({ v3: 40, v4: 5000 })

      expect(auth_token.safe_to_use?(:v3)).to eq(false)
      expect(auth_token.safe_to_use?(:v4)).to eq(true)
    end
  end

  describe "#fetch_resource_limits" do
    subject(:limit_stats) do
      VCR.use_cassette("github/chalk_api", match_requests_on: %i[method uri body query]) do
        auth_token.fetch_resource_limits
      end
    end

    let(:auth_token) { described_class.new(token: token_value) }
    let(:token_value) { "foo" }

    it "returns rate limit stats for Github REST API (V3)" do
      expect(limit_stats[:v3]).to eq(4999)
    end

    it "returns rate limit stats for Github GraphQL API (V4)" do
      expect(limit_stats[:v4]).to eq(4998)
    end
  end
end
