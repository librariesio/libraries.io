require "rails_helper"

describe "API::StatusController" do
  let(:user) { create(:user) }
  let!(:project) { create(:project) }
  describe "GET /api/check", type: :request do
    it "renders successfully" do
      post "/api/check", params: {api_key: user.api_key, projects: [{name: 'rails', platform: 'rubygems'}] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql []
    end
  end
end
