# frozen_string_literal: true

require "rails_helper"

describe "Api::RepositoriesController" do
  let!(:repository) { create(:repository) }
  let!(:maintenance_stat) { create(:repository_maintenance_stat, repository: repository) }
  let(:internal_user) { create(:user) }

  before do
    internal_user.current_api_key.update_attribute(:is_internal, true)
  end

  describe "GET /api/github/:owner/:name/dependencies", type: :request do
    it "renders successfully" do
      get "/api/github/#{repository.full_name}/dependencies"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(json.to_json).to be_json_eql repository.as_json({ except: %i[id maintenance_stats_refreshed_at repository_organisation_id repository_user_id], methods: %i[github_contributions_count github_id] }).merge(dependencies: []).to_json
    end
  end

  context "with dependencies" do
    let!(:manifest) { create(:manifest, repository: repository) }

    let!(:deprecated_project) { create(:project, status: "Deprecated", repository: repository) }
    let!(:deprecated_dependency) { create(:repository_dependency, repository: repository, manifest: manifest, project: deprecated_project) }

    let!(:outdated_project) { create(:project, repository: repository) }
    let!(:outdated_dependency) { create(:repository_dependency, repository: repository, requirements: "<1.0.0", manifest: manifest, project: outdated_project) }

    describe "GET /api/github/:owner/:name/shields_dependencies", type: :request do
      it "renders successfully" do
        # TODO: for some reason the factory can't save these
        outdated_project.update_columns(latest_stable_release_number: "9.9.9", latest_release_number: "9.9.9")

        get "/api/github/#{repository.full_name}/shields_dependencies"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to start_with("application/json")
        expect(json.to_json).to eq({ deprecated_count: 1, outdated_count: 1 }.to_json)
      end
    end
  end

  describe "GET /api/github/:owner/:name/projects", type: :request do
    it "renders successfully" do
      get "/api/github/#{repository.full_name}/projects"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(json).to eq []
    end
  end

  describe "GET /api/github/:owner/:name", type: :request do
    it "renders successfully" do
      get "/api/github/#{repository.full_name}", params: { api_key: internal_user.api_key }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(json.to_json).to be_json_eql(
        repository.to_json({
                             except: %i[id maintenance_stats_refreshed_at repository_organisation_id repository_user_id],
                             methods: %i[github_contributions_count github_id],
                           })
      ).excluding("maintenance_stats") # exclude maintenance stats since those are not included in the serializer

      expect(json["maintenance_stats"].to_json).to be_json_eql([maintenance_stat.attributes.symbolize_keys.slice(*RepositoryMaintenanceStat::API_FIELDS)].to_json)
    end
  end
end
