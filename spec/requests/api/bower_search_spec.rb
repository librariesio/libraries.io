require "rails_helper"

describe "Api::BowerSearchController" do
  describe "GET /api/bower-search", type: :request do
    it "renders successfully" do
      get '/api/bower-search'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json).to eq []
    end
  end
end
