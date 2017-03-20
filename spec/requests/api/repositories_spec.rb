require "rails_helper"

describe "Api::RepositoriesController" do
  before :each do
    @repo = create(:repository)
  end

  describe "GET /api/github/search", type: :request do
    it "renders successfully" do
      get '/api/github/search'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json).to eq []
    end
  end

  describe "GET /api/github/:owner/:name/dependencies", type: :request do
    it "renders successfully" do
      get "/api/github/#{@repo.full_name}/dependencies"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json.to_json).to be_json_eql @repo.as_json({except: [:id, :github_organisation_id, :owner_id], methods: [:github_contributions_count, :github_id]}).merge(dependencies: []).to_json
    end
  end

  describe "GET /api/github/:owner/:name/projects", type: :request do
    it "renders successfully" do
      get "/api/github/#{@repo.full_name}/projects"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json).to eq []
    end
  end

  describe "GET /api/github/:owner/:name", type: :request do
    it "renders successfully" do
      get "/api/github/#{@repo.full_name}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json.to_json).to be_json_eql @repo.to_json({except: [:id, :github_organisation_id, :owner_id], methods: [:github_contributions_count, :github_id]})
    end
  end
end
