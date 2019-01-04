require "rails_helper"

describe "API::StatusController" do
  let(:user) { create(:user) }
  let!(:project) { create(:project) }
  let!(:project_django) { create(:project, name: 'Django', platform: 'Pypi') }
  let!(:repository) { create(:repository) }
  let!(:maintenance_stat) { create(:repository_maintenance_stat, repository: repository)}

  before do
    user.current_api_key.update_attribute(:is_internal, true)

    project.repository = repository
    project.save!
  end

  describe "GET /api/check", type: :request do
    it "renders successfully with one" do
      post "/api/check", params: {api_key: user.api_key, projects: [{name: project.name, platform: project.platform}] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body.include?(project.name)).to be == true
      
      # check for maintenance stats being returned
      json_response = JSON.parse(response.body)
      maintenance_stats = json_response.first["repository_maintenance_stats"]
      expect(maintenance_stats.length).to be 1
      expect(maintenance_stats.first["category"]).to eql maintenance_stat.category
      expect(maintenance_stats.first["value"]).to eql maintenance_stat.value
    end

    it "renders empty json list if cannot find Project" do
      post "/api/check", params: {api_key: user.api_key, projects: [{name: 'rails', platform: 'rubygems'}] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql []
    end

    it "renders successfully" do
      post "/api/check", params: {api_key: user.api_key, projects: [{name: project.name, platform: 'rubygems'}, {name: 'django', platform: 'Pypi'}] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body.include?(project.name)).to be == true
      expect(response.body.include?('Django')).to be == true
    end

    it "renders empty maintenance stats if they don't exist" do
      post "/api/check", params: {api_key: user.api_key, projects: [{name: project_django.name, platform: project_django.platform}] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body.include?(project_django.name)).to be == true

      json_response = JSON.parse(response.body)
      expect(json_response.first["repository_maintenance_stats"].length).to be 0
    end

    context "with normal API key" do
      before do
        user.current_api_key.update_attribute(:is_internal, false)
      end

      it "returns no maintenance stats" do
        post "/api/check", params: {api_key: user.api_key, projects: [{name: project_django.name, platform: project_django.platform}] }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq('application/json')
        expect(response.body.include?(project_django.name)).to be == true

        json_response = JSON.parse(response.body)
        expect(json_response.first.key? "repository_maintenance_stats").to be false
      end
    end
  end
end
