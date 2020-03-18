# frozen_string_literal: true

require "rails_helper"

describe "API::SearchController" do
  describe "GET /api/search", type: :request do
    it "renders successfully" do
      get "/api/search"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to be_json_eql []
    end
  end
end
