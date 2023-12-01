# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GithubGraphql", type: :service do
  subject(:service) { GithubGraphql }

  describe "::new_client" do
    let(:token) { "" }

    it "builds wrapper client" do
      expect(service.new_client(token)).to be_a(GithubGraphql::Client)
    end
  end

  describe "::parse_query" do
    let(:query) { "{}" }

    it "parses static query strings into constants" do
      expect(service.parse_query(query)).to be_a(GraphQL::Client::OperationDefinition)
    end
  end

  describe "::refresh_dump!" do
    let(:token) { "test_token" }
    let(:destination) { "tmp/github_graphql_test_dump.json" }

    after do
      FileUtils.rm_f(destination)
    end

    it "updates the local github graphql api schema cache" do
      VCR.use_cassette("github/graphql_schema") do
        service.refresh_dump!(token: token, destination: destination)
      end

      expect(File.exist?(destination)).to eq(true)
      expect(File.read(destination)).to be_present
    end
  end
end
