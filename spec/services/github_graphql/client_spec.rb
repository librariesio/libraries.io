# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GithubGraphql::Client" do
  TEST_QUERY = GithubGraphql.parse_query "query { viewer }"  # rubocop: disable Lint/ConstantDefinitionInBlock

  let(:client) { GithubGraphql::Client.new(token) }
  let(:token) { "test_token" }

  describe "#query" do
    subject(:response) do
      VCR.use_cassette("github/chalk_api", match_requests_on: %i[method uri body query]) do
        client.query(
          MaintenanceStats::Queries::Github::RepoReleasesQuery::RELEASES_QUERY,
          variables: { owner: "chalk", repo_name: "chalk" }
        )
      end
    end

    context "successful request" do
      it "returns wrapped response" do
        expect(response).to be_a(GithubGraphql::Response)
        expect(response.status_code).to eq("200")
        expect(response.headers.keys).to include("x-ratelimit-remaining")
        expect(response.data.to_h).to_not be_empty
        expect(response.errors).to be_empty
      end
    end
  end

  describe "#query!" do
    let(:stub_response) { instance_double("GithubGraphql::Response", unauthorized?: unauthorized?, rate_limited?: rate_limited?, errors?: errors?) }
    let(:unauthorized?) { false }
    let(:rate_limited?) { false }
    let(:errors?) { false }

    before { expect(client).to receive(:query).and_return(stub_response) }

    context "when unauthorized" do
      let(:unauthorized?) { true }

      it "raises AuthorizationError" do
        expect do
          client.query!(TEST_QUERY)
        end.to raise_error(GithubGraphql::AuthorizationError)
      end
    end

    context "when token rate-limit exhausted" do
      let(:rate_limited?) { true }

      it "raises RateLimitError" do
        expect do
          client.query!(TEST_QUERY)
        end.to raise_error(GithubGraphql::RateLimitError)
      end
    end

    context "when API returns with errors" do
      let(:errors?) { true }

      it "raises RequestError" do
        expect do
          client.query!(TEST_QUERY)
        end.to raise_error(GithubGraphql::RequestError)
      end
    end
  end
end
