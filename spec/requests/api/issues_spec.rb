require "rails_helper"

describe "Api::IssuesController" do
  let!(:issue) { create(:issue) }

  describe "GET /api/github/issues/help-wanted", type: :request do
    it "renders successfully" do
      get '/api/github/issues/help-wanted'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json).to eq []
    end
  end

  describe "GET /api/github/issues/first-pull-request", type: :request do
    it "renders successfully" do
      get '/api/github/issues/first-pull-request'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json).to eq []
    end
  end
end
