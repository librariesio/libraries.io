# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GithubGraphql::Response" do
  subject(:response) { described_class.new(raw_graphql_response) }
  let(:raw_graphql_response) { {} }

  xdescribe "#errors?" do
    context "when response has root level errors" do
      it "returns true" do
        expect(response.errors?).to eq(true)
      end
    end

    context "when response has errors on data" do
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

  xdescribe "#unauthorized?" do
    context "when response contains a 401 error" do
      it "returns true" do
        expect(response.unauthorized?).to eq(true)
      end
    end

    context "when response contains other error" do
      it "returns false" do
        expect(response.unauthorized?).to eq(false)
      end
    end

    context "when response contains no errors" do
      it "returns false" do
        expect(response.unauthorized?).to eq(false)
      end
    end
  end

  xdescribe "#rate_limited?" do
    context "when response contains a 401 error" do
      it "returns true" do
        expect(response.unauthorized?).to eq(true)
      end
    end

    context "when response contains other error" do
      it "returns false" do
        expect(response.unauthorized?).to eq(false)
      end
    end

    context "when response contains no errors" do
      it "returns false" do
        expect(response.unauthorized?).to eq(false)
      end
    end
  end

  describe "#dig"
end
