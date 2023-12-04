# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GithubGraphql::Response", type: :service do
  def stub_gem_response(headers:, status_code:, data:, errors:)
    instance_double(
      "GraphQL::Client::Response", {
        original_hash: { "headers" => headers.stringify_keys, "status_code" => status_code },
        data: data.stringify_keys,
        errors: instance_double("GraphQL::Client::Errors", messages: errors),
      }
    )
  end

  subject(:response) do
    GithubGraphql::Response.new(
      stub_gem_response(headers: headers, status_code: status_code, data: data, errors: errors)
    )
  end

  let(:status_code) { "200" }
  let(:headers) { {} }
  let(:data) { {} }
  let(:errors) { {} }

  describe "#errors?" do
    context "when response has root level errors" do
      let(:errors) { { data: "Oopsie" } }

      it "returns true" do
        expect(response.errors?).to eq(true)
      end
    end

    context "when response has errors on data" do
      let(:data) { { errors: "Oopsie" } }

      it "returns true" do
        expect(response.errors?).to eq(true)
      end
    end

    context "when success" do
      it "returns false" do
        expect(response.errors?).to eq(false)
      end
    end
  end

  describe "#unauthorized?" do
    context "when response has 401 status" do
      let(:status_code) { "401" }

      it "returns true" do
        expect(response.unauthorized?).to eq(true)
      end
    end

    context "when response contains 401 error" do
      let(:errors) { { data: "401 Unauthorized" } }

      it "returns true" do
        expect(response.unauthorized?).to eq(true)
      end
    end

    context "when response contains no errors" do
      let(:status_code) { "200" }

      it "returns false" do
        expect(response.unauthorized?).to eq(false)
      end
    end
  end

  describe "#rate_limited?" do
    context "when response contains exhausted ratelimit header" do
      let(:headers) { { "x-ratelimit-remaining" => "0" } }

      it "returns true" do
        expect(response.rate_limited?).to eq(true)
      end
    end

    context "when response contains ratelimit header with good value" do
      let(:headers) { { "x-ratelimit-remaining" => "4000" } }

      it "returns false" do
        expect(response.rate_limited?).to eq(false)
      end
    end

    context "when response contains no ratelimit info" do
      let(:headers) { {} }

      it "returns false" do
        expect(response.rate_limited?).to eq(false)
      end
    end
  end
end
