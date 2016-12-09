require "rails_helper"

describe "Api::GithubRepositoriesController" do
  before :each do
    @repo = create(:github_repository)
  end

  describe "GET /api/github/search", :vcr, type: :request do
    it "renders successfully" do
      get '/api/github/search'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json).to eq []
    end
  end

  describe "GET /api/github/:owner/:name/dependencies", :vcr, type: :request do
    it "renders successfully" do
      get "/api/github/#{@repo.full_name}/dependencies"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json.to_json).to be_json_eql @repo.as_json({except: [:id, :github_organisation_id, :owner_id]}).merge(dependencies: []).to_json
    end
  end

  describe "GET /api/github/:owner/:name/projects", :vcr, type: :request do
    it "renders successfully" do
      get "/api/github/#{@repo.full_name}/projects"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json).to eq []
    end
  end

  describe "GET /api/github/:owner/:name", :vcr, type: :request do
    it "renders successfully" do
      get "/api/github/#{@repo.full_name}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json.to_json).to be_json_eql @repo.to_json({except: [:id, :github_organisation_id, :owner_id]})
    end
  end
end
