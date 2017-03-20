require "rails_helper"

describe "Api::ProjectsController" do
  let!(:project) { create(:project) }

  describe "GET /api/:platform/:name", type: :request do
    it "renders successfully" do
      get "/api/#{project.platform}/#{project.name}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql project_json_response(project).to_json
    end
  end

  describe "GET /api/:platform/:name/dependents", type: :request do
    it "renders successfully" do
      get "/api/#{project.platform}/#{project.name}/dependents"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql []
    end
  end

  describe "GET /api/:platform/:name/dependent_repositories", type: :request do
    it "renders successfully" do
      get "/api/#{project.platform}/#{project.name}/dependent_repositories"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql []
    end
  end

  describe "GET /api/searchcode", type: :request do
    it "renders successfully" do
      get "/api/searchcode"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql [project.repository_url].to_json
    end
  end
end
