# frozen_string_literal: true

require "rails_helper"

describe "auth tokens" do
  describe "reverify_authorized" do
    after do
      # need to run this after each spec to make sure the rake task can be called again
      # otherwise it will be a no-op when called instead of running the intended task code
      Rake::Task["auth_tokens:reverify_authorized"].reenable
    end

    context "with single token" do
      let(:token) { create(:auth_token) }
      let(:token_github_api_stub) { instance_double(Octokit::Client) }
      let(:token_response_stub) { instance_double(Sawyer::Response) }

      before do
        allow(Octokit::Client).to receive(:new).with(hash_including(access_token: token.token)).and_return(token_github_api_stub)
        allow(token_github_api_stub).to receive(:last_response).and_return(token_response_stub)
        allow(token_github_api_stub).to receive(:user).and_return({ login: "login" })
      end

      it "marks unauthorized tokens" do
        # verify the token would mark itself as unauthorized and is currently authorized
        allow(token_github_api_stub).to receive(:rate_limit).and_return(false)
        expect(token.still_authorized?).to be false
        expect(token.authorized).to be nil

        Rake::Task["auth_tokens:reverify_authorized"].invoke

        expect(token.reload.authorized).to be false
      end

      it "saves token scopes" do
        # return as still_authorized
        allow(token_github_api_stub).to receive(:rate_limit).and_return(5000)

        expected_scopes = "some, fun, scopes"
        allow(token_response_stub).to receive(:headers).and_return({ "x-oauth-scopes" => expected_scopes })

        expect(token.scopes).to be_empty

        Rake::Task["auth_tokens:reverify_authorized"].invoke

        expect(token.reload.scopes).to match_array(expected_scopes.split(", "))
      end
    end

    context "with exhausted token" do
      let(:error_token) { create(:auth_token) }
      let(:error_github_api_stub) { instance_double(Octokit::Client) }
      let(:unauthed_token) { create(:auth_token) }
      let(:unauthed_github_api_stub) { instance_double(Octokit::Client) }

      before do
        # stub error api
        allow(Octokit::Client).to receive(:new).with(hash_including(access_token: error_token.token)).and_return(error_github_api_stub)

        # stub token2 api client
        allow(Octokit::Client).to receive(:new).with(hash_including(access_token: unauthed_token.token)).and_return(unauthed_github_api_stub)

        # ordering matters here since the rake task is using `find_each` which orders by ID
        # so token will be the first to be called so make sure it is the one to error to verify
        # the loop is not broken
        allow(error_github_api_stub).to receive(:rate_limit).and_raise(Octokit::TooManyRequests)

        # token2 raises too many requests error from API
        allow(unauthed_github_api_stub).to receive(:rate_limit).and_return(false)
      end

      it "skips token with exhausted rate limit" do
        expect { Rake::Task["auth_tokens:reverify_authorized"].invoke }.not_to raise_error

        expect(error_token.reload.authorized).to be nil
        expect(unauthed_token.reload.authorized).to be false
      end
    end
  end
end
