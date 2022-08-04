# frozen_string_literal: true

require "rails_helper"

describe "API::SearchController" do
  describe "GET /api/search", type: :request do
    let!(:user) { create(:user) }

    context "with missing api key" do
      it "returns an error" do
        get "/api/search"

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with internal api key" do
      before :each do
        user.current_api_key.update_attribute(:is_internal, true)
      end

      it "renders successfully" do
        get "/api/search?api_key=#{user.api_key}"

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq('application/json')
        expect(response.body).to be_json_eql []
      end
    end
  end
end
