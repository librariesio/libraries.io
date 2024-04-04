# frozen_string_literal: true

require "rails_helper"

describe "Api::ApplicationController", type: :request do
  describe "an arbitrary API request" do
    let!(:user) { create(:user, :internal) }

    context "when not rate-limited" do
      before { ApiKey.first.update(rate_limit: 12345) }

      # These are set in Api::ApplicationController
      it "includes rate limit headers" do
        get "/api/versions", params: { since: 1.day.ago, api_key: user.api_key }

        expect(response).to have_http_status(:success)
        expect(response.headers["X-RateLimit-Limit"]).to eq("12345")
        expect(response.headers["X-RateLimit-Remaining"]).to eq("12344")
        expect(response.headers["X-RateLimit-Reset"]).to match(/\d+/)
      end
    end

    context "when rate-limited" do
      before { ApiKey.first.update(rate_limit: 0) }

      # These are set in Rack::Attack's throttled_responder
      it "includes rate limit headers" do
        get "/api/versions", params: { since: 1.day.ago, api_key: user.api_key }

        expect(response).to have_http_status(:too_many_requests)
        expect(response.headers["X-RateLimit-Limit"]).to eq("0")
        expect(response.headers["X-RateLimit-Remaining"]).to eq("0")
        expect(response.headers["X-RateLimit-Reset"]).to match(/\d+/)
        expect(response.headers["Retry-After"]).to eq(response.headers["X-RateLimit-Reset"])
      end
    end
  end
end
