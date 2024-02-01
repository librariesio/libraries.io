# frozen_string_literal: true

require "rails_helper"

describe "API::SearchController", elasticsearch: true do
  describe "GET /api/search", type: :request do
    let!(:user) { create(:user) }

    context "with missing api key" do
      it "returns forbidden" do
        get "/api/search"

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an invalid api key" do
      it "returns forbidden" do
        get "/api/search?api_key=abc123"

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with valid api key" do
      it "renders successfully" do
        get "/api/search?api_key=#{user.api_key}"

        expect(response).to have_http_status(:success)
        expect(response.content_type).to start_with("application/json")
        expect(response.body).to be_json_eql []
      end
    end

    context "with pg_search_projects enabled" do
      let!(:project) { create :project, name: "charisma-generator" }
      let!(:other_project) { create :project, name: "wisdom-generator" }

      before do
        expect_any_instance_of(ApplicationController).to receive(:use_pg_search?).and_return(true)
        allow_any_instance_of(ApplicationController).to receive(:es_query).and_raise
      end

      it "renders successfully" do
        get "/api/search", params: { api_key: user.api_key, q: "charisma" }
        expect(response.content_type).to start_with("application/json")
        expect(response.body).to match [ProjectSerializer.new(project)].to_json
      end
    end
  end
end
