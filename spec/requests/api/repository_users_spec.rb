# frozen_string_literal: true

require "rails_helper"

describe "Api::RepositoryUsersController" do
  before :each do
    @user = create(:repository_user)
  end

  describe "GET /api/github/:login", type: :request do
    it "renders successfully" do
      get "/api/github/#{@user.login}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(response.body["github_id"]).to eq(@user.to_json({ methods: %i[github_id user_type] })["github_id"])
    end
  end

  describe "GET /api/github/:login/repositories", type: :request do
    it "renders successfully" do
      repo = create(:repository, repository_user: @user)
      get "/api/github/#{@user.login}/repositories"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(response.body).to be_json_eql [repo.as_json({ except: %i[id maintenance_stats_refreshed_at repository_organisation_id repository_user_id status_reason], methods: %i[github_contributions_count github_id] })].to_json
    end
  end

  describe "GET /api/github/:login/projects", type: :request do
    it "renders successfully" do
      get "/api/github/#{@user.login}/projects"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(json).to eq []
    end
  end

  describe "GET /api/github/:login/project-contributions", type: :request do
    it "renders successfully" do
      get "/api/github/#{@user.login}/project-contributions"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(json).to eq []
    end
  end

  describe "GET /api/github/:login/repository-contributions", type: :request do
    it "renders successfully" do
      get "/api/github/#{@user.login}/repository-contributions"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(json).to eq []
    end
  end

  describe "GET /api/github/:login/dependencies", type: :request do
    it "renders successfully" do
      get "/api/github/#{@user.login}/dependencies"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(json).to eq []
    end
  end
end
