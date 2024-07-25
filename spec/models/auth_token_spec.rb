# frozen_string_literal: true

require "rails_helper"

describe AuthToken, type: :model do
  it { should validate_presence_of(:token) }

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

  describe "find_token" do
    let(:scope1) { "scope1" }
    let(:scope2) { "scope2" }
    let!(:auth_token1) { create(:auth_token, scopes: [scope1, scope2]) }
    let!(:auth_token2) { create(:auth_token, scopes: [scope2]) }
    let(:token_github_api_stub) { instance_double(Octokit::Client) }

    before do
      allow(Octokit::Client).to receive(:new).with(hash_including(access_token: auth_token1.token)).and_return(token_github_api_stub)
      allow(Octokit::Client).to receive(:new).with(hash_including(access_token: auth_token2.token)).and_return(token_github_api_stub)
      allow(token_github_api_stub).to receive_message_chain(:rate_limit!, :remaining).and_return(5000)
      allow(token_github_api_stub).to receive_message_chain(:last_response, :data, :resources, :graphql, :remaining).and_return(5000)
    end

    it "finds auth token with scope" do
      result = described_class.find_token(:v3, required_scope: [scope1])
      expect(result).to eql(auth_token1)
    end
  end

  describe "has_scope" do
    let(:scope1) { "scope1" }
    let(:scope2) { "scope2" }
    let!(:auth_token1) { create(:auth_token, scopes: [scope1, scope2]) }
    let!(:auth_token2) { create(:auth_token, scopes: [scope2]) }

    it "finds auth token with scope" do
      result = described_class.has_scope(scope1)
      expect(result.size).to eql(1)
      expect(result.first).to eql(auth_token1)
    end

    it "finds auth tokens with either scope" do
      result = described_class.has_scope([scope1, scope2])
      expect(result.size).to eql(2)
      expect(result.ids).to contain_exactly(auth_token1.id, auth_token2.id)
    end

    it "does not find tokens with missing scope" do
      result = described_class.has_scope("something-else")
      expect(result.size).to eql(0)
    end
  end
end
