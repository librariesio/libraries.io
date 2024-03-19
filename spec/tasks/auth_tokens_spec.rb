# frozen_string_literal: true

require "rails_helper"

describe "auth tokens" do
  describe "reverify_authorized" do
    let(:token) { create(:auth_token) }
    let(:token_github_api_stub) { instance_double(Octokit::Client) }

    before do
      allow(Octokit::Client).to receive(:new).with(hash_including(access_token: token.token)).and_return(token_github_api_stub)
    end

    it "marks unauthorized tokens" do
      # verify the token would mark itself as unauthorized and is currently authorized
      allow(token_github_api_stub).to receive(:rate_limit).and_return(false)
      expect(token.still_authorized?).to be false
      expect(token.authorized).to be nil

      Rake::Task["auth_tokens:reverify_authorized"].invoke

      expect(token.reload.authorized).to be false
    end

    context "with exhausted token" do
      let(:token2) { create(:auth_token) }
      let(:token2_github_api_stub) { instance_double(Octokit::Client) }

      before do
        # stub token2 api client
        allow(Octokit::Client).to receive(:new).with(hash_including(access_token: token2.token)).and_return(token2_github_api_stub)

        # ordering matters here since the rake task is using `find_each` which orders by ID
        # so token will be the first to be called so make sure it is the one to error to verify
        # the loop is not broken
        allow(token_github_api_stub).to receive(:rate_limit).and_raise(Octokit::TooManyRequests)

        # token2 raises too many requests error from API
        allow(token2_github_api_stub).to receive(:rate_limit).and_return(false)
      end

      it "skips token with exhausted rate limit" do
        expect { Rake::Task["auth_tokens:reverify_authorized"].invoke }.not_to raise_error

        expect(token.reload.authorized).to be nil
        expect(token2.reload.authorized).to be false
      end
    end
  end
end
