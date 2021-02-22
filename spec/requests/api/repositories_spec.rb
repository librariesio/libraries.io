# frozen_string_literal: true
require "rails_helper"

describe "Api::RepositoriesController" do
  let!(:repository) { create(:repository) }

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
      get "/api/github/#{repository.full_name}/dependencies"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json.to_json).to be_json_eql repository.as_json({except: [:id, :repository_organisation_id, :repository_user_id], methods: [:github_contributions_count, :github_id]}).merge(dependencies: []).to_json
    end
  end

  describe "GET /api/github/:owner/:name/projects", type: :request do
    it "renders successfully" do
      get "/api/github/#{repository.full_name}/projects"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json).to eq []
    end
  end

  describe "GET /api/github/:owner/:name", type: :request do
    it "renders successfully" do
      get "/api/github/#{repository.full_name}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json.to_json).to be_json_eql repository.to_json({except: [:id, :repository_organisation_id, :repository_user_id], methods: [:github_contributions_count, :github_id]})
    end
  end
end
