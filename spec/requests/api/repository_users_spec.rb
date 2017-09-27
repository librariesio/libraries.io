require "rails_helper"

describe "Api::RepositoryUsersController" do
  before :each do
    @user = create(:repository_user)
  end

  describe "GET /api/github/:login", type: :request do
    it "renders successfully" do
      get "/api/github/#{@user.login}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql @user.to_json({methods: [:github_id, :user_type]})
    end
  end

  describe "GET /api/github/:login/repositories", type: :request do
    it "renders successfully" do
      repo = create(:repository, repository_user: @user)
      get "/api/github/#{@user.login}/repositories"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql [repo.as_json({except: [:id, :repository_organisation_id, :repository_user_id], methods: [:github_contributions_count, :github_id]})].to_json
    end
  end

  describe "GET /api/github/:login/projects", type: :request do
    it "renders successfully" do
      get "/api/github/#{@user.login}/projects"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json).to eq []
    end
  end
end
