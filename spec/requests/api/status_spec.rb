require "rails_helper"

describe "API::StatusController" do
  let(:user) { create(:user) }
  let!(:project) { create(:project) }
  let!(:project_django) {create(:project, name: 'Django', platform: 'Pypi')}

  describe "GET /api/check", type: :request do
    it "renders successfully with one" do
      post "/api/check", params: {api_key: user.api_key, projects: [{name: 'rails1', platform: 'rubygems'}] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql []
    end

    it "renders successfully with one missing" do
      post "/api/check", params: {api_key: user.api_key, projects: [{name: 'rails', platform: 'rubygems'}] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql []
    end

    it "renders successfully" do
      post "/api/check", params: {api_key: user.api_key, projects: [{name: 'rails1', platform: 'rubygems'}, {name: 'django', platform: 'Pypi'}] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body.include?('Django')).to be == true
      expect(response.body.include?('rails1')).to be == true
    end
  end
end
