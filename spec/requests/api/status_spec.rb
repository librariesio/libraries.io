require "rails_helper"

describe "API::StatusController" do
  let(:internal_user) { create(:user) }
  let(:normal_user) { create(:user) }
  let!(:repository) { create(:repository) }
  let!(:maintenance_stat) { create(:repository_maintenance_stat, repository: repository)}
  let!(:project) { create(:project, repository: repository) }
  let!(:project_django) { create(:project, name: 'Django', platform: 'Pypi') }

  before do
    internal_user.current_api_key.update_attribute(:is_internal, true)
  end

  describe "GET /api/check", type: :request do
    it "renders successfully with one" do
      post "/api/check", params: {api_key: internal_user.api_key, projects: [{name: project.name, platform: project.platform}] }
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
      post "/api/check", params: {api_key: internal_user.api_key, projects: [{name: 'rails', platform: 'rubygems'}] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql []
    end

    it "renders successfully" do
      post "/api/check", params: {api_key: internal_user.api_key, projects: [{name: project.name, platform: 'rubygems'}, {name: 'django', platform: 'Pypi'}] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body.include?(project.name)).to be == true
      expect(response.body.include?('Django')).to be == true
    end

    it "renders empty maintenance stats if they don't exist" do
      post "/api/check", params: {api_key: internal_user.api_key, projects: [{name: project_django.name, platform: project_django.platform}] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body.include?(project_django.name)).to be == true

      json_response = JSON.parse(response.body)
      expect(json_response.first["repository_maintenance_stats"].length).to be 0
    end

    it "contains all expected fields" do
      # all the fields we expect to come back in the response for a project
      expected_fields = [
        "name", "platform", "description", "homepage", "repository_url", "normalized_licenses",
        "rank", "latest_release_published_at", "latest_release_number", "dependents_count",
        "language", "status", "dependent_repos_count", "score", "latest_stable_release_number",
        "latest_stable_release_published_at", "package_manager_url", "stars", "forks",
        "keywords", "latest_download_url", "versions", "repository_maintenance_stats"
      ]

      post "/api/check", params: {api_key: internal_user.api_key, projects: [{name: project_django.name, platform: project_django.platform}], score: true }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')

      json_response = JSON.parse(response.body)
      project = json_response.first
      expected_fields.each do |field|
        expect(project.key? field).to be true
      end
    end

    it "correctly serves the original name" do
      requested_name = project_django.name.downcase

      post(
        "/api/check",
        params: {
          api_key: internal_user.api_key,
          projects: [
            { name: requested_name, platform: project_django.platform }
          ],
          score: true
        }
      )

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).dig(0, "name")).to eq(requested_name)
    end

    it "correctly handles go redirects" do
      project = create(:project, platform: "Go", name: "known/project")
      requested_name = "unknown/project"
      allow(PackageManager::Go)
        .to receive(:project_find_names)
        .with(requested_name)
        .and_return([project.name])

      post(
        "/api/check",
        params: {
          api_key: internal_user.api_key,
          projects: [
            { name: requested_name, platform: project.platform }
          ],
          score: true
        }
      )

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).dig(0, "name")).to eq(requested_name)
    end

    context "with normal API key" do

      it "returns no maintenance stats" do
        post "/api/check", params: {api_key: normal_user.api_key, projects: [{name: project_django.name, platform: project_django.platform}] }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq('application/json')
        expect(response.body.include?(project_django.name)).to be == true

        json_response = JSON.parse(response.body)
        expect(json_response.first.key? "repository_maintenance_stats").to be false
      end
    end
  end
end
