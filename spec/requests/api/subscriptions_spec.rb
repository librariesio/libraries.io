require "rails_helper"

describe "Api::SubscriptionsController" do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let!(:subscription) { create(:subscription, user: user, project: project) }

  describe "GET /api/subscriptions", type: :request do
    it "renders successfully" do
      get "/api/subscriptions?api_key=#{user.api_key}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql [subscription.as_json(only: [:include_prerelease, :created_at, :updated_at], include: {project: {only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords, :latest_download_url, :repository_license], include: {versions: {only: [:number, :published_at]} }}})].to_json
    end
  end

  describe "GET /api/subscriptions/:platform/:name", type: :request do
    it "renders successfully" do
      get "/api/subscriptions/#{subscription.project.platform}/#{subscription.project.name}?api_key=#{user.api_key}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql subscription.to_json(only: [:include_prerelease, :created_at, :updated_at], include: {project: {only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords, :latest_download_url, :repository_license], include: {versions: {only: [:number, :published_at]} }}})
    end
  end

  describe "POST /api/subscriptions/:platform/:name", type: :request do
    it "renders successfully" do
      post "/api/subscriptions/#{project.platform}/#{project.name}?api_key=#{user.api_key}", params: { subscription: { include_prerelease: true } }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
    end
  end

  describe "POST /api/subscriptions/:platform/:name with no body", type: :request do
    it "renders successfully" do
      post "/api/subscriptions/#{project.platform}/#{project.name}?api_key=#{user.api_key}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
    end
  end

  describe "PUT /api/subscriptions/:platform/:name", type: :request do
    it "renders successfully" do
      put "/api/subscriptions/#{subscription.project.platform}/#{subscription.project.name}?api_key=#{user.api_key}", params: { subscription: { include_prerelease: true } }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql subscription.reload.to_json(only: [:include_prerelease, :created_at, :updated_at], include: {project: {only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords, :latest_download_url, :repository_license], include: {versions: {only: [:number, :published_at]} }}})
    end
  end

  describe "DELETE /api/subscriptions/:platform/:name", type: :request do
    it "renders successfully" do
      delete "/api/subscriptions/#{subscription.project.platform}/#{subscription.project.name}?api_key=#{user.api_key}"
      expect(response).to have_http_status(204)
    end
  end
end
