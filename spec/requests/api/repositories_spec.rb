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
    let!(:project) { create(:project, repository: repository) }
    let!(:version) { create(:version, project: project) }
    let!(:dependency) { create(:dependency, version: version) }

    it "renders successfully" do
      get "/api/github/#{repository.full_name}/dependencies"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(json.to_json).to be_json_eql(
        repository
          .as_json(
            {
              except: %i[id maintenance_stats_refreshed_at repository_organisation_id repository_user_id],
              methods: %i[github_contributions_count github_id],
            }
          )
          .merge(dependencies: [
            {
              project_name: "rails",
              name: "rails",
              platform: "Rubygems",
              requirements: "~> 4.2",
              latest_stable: nil,
              latest: nil,
              deprecated: false,
              outdated: nil,
              filepath: nil,
              kind: "runtime",
              optional: false,
              normalized_licenses: ["MIT"],
            },
          ])
          .to_json
      )
    end
  end

  describe "GET /api/repository/projects", type: :request do
    let!(:project) { create(:project, repository: repository) }
    let!(:hidden_project) { create(:project, status: "Hidden", repository: repository) }
    let(:internal_user) { create(:user) }

    before do
      internal_user.current_api_key.update_attribute(:is_internal, true)
    end

    it "renders visible project names" do
      get "/api/repository/projects", params: { host_type: repository.host_type, owner: repository.owner_name, name: repository.project_name, api_key: internal_user.api_key }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")

      expect(json).to contain_exactly(
        { "name" => project.name, "platform" => project.platform }
      )
    end
  end

  describe "GET /api/github/:owner/:name/shields_dependencies", type: :request do
    let!(:project) { create(:project, repository: repository) }
    let!(:version) { create(:version, project: project) }

    let!(:deprecated_project) { create(:project, status: "Deprecated") }
    let!(:deprecated_dependency) { create(:dependency, project: deprecated_project, version: version) }

    let!(:outdated_project) { create(:project, repository: repository) }
    let!(:outdated_dependency) { create(:dependency, requirements: "<1.0.0", project: outdated_project, version: version) }

    it "renders successfully" do
      # TODO: for some reason the factory can't save these
      outdated_project.update_columns(latest_stable_release_number: "9.9.9", latest_release_number: "9.9.9")

      get "/api/github/#{repository.full_name}/shields_dependencies"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(json.to_json).to eq({ deprecated_count: 1, outdated_count: 1 }.to_json)
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

  # specs to share between the two different URL routes for the repository#show endpoint
  # must define url and params
  shared_examples "repository#show" do
    it "renders successfully" do
      get url, params: params
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

    context "when repository has a readme" do
      before do
        repository.update(readme: build(:readme, html_body: "<html>this is my readme</html>"))
      end

      it "doesn't include readme when include_readme=false" do
        get url, params: params.merge(include_readme: false)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to start_with("application/json")
        expect(json.as_json.keys).to_not include("readme_html_body")
      end

      it "includes readme when include_readme=true" do
        get url, params: params.merge(include_readme: true)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to start_with("application/json")
        expect(json.as_json.keys).to include("readme_html_body")
        expect(json["readme_html_body"]).to include("this is my readme")
      end
    end
  end

  describe "GET /api/github/:owner/:name", type: :request do
    let(:url) { "/api/github/#{repository.full_name}" }
    let(:params) { { api_key: internal_user.api_key } }

    it_behaves_like "repository#show"
  end

  describe "GET /api/github/repository", type: :request do
    let(:url) { "/api/github/repository" }
    let(:params) { { api_key: internal_user.api_key, owner: repository.owner_name, name: repository.project_name } }

    it_behaves_like "repository#show"

    it "returns error on missing owner param" do
      get url, params: params.except(:owner)
      expect(response).to have_http_status(:bad_request)
      expect(response.content_type).to start_with("application/json")
      expect(json).to eql({ "owner" => ["is required"] })
    end

    it "returns error on missing name param" do
      get url, params: params.except(:name)
      expect(response).to have_http_status(:bad_request)
      expect(response.content_type).to start_with("application/json")
      expect(json).to eql({ "name" => ["is required"] })
    end
  end

  describe "GET /api/github/:owner/:name/sync", type: :request do
    context "without api key" do
      it "forbids action" do
        get "/api/github/#{repository.full_name}/sync"

        expect(response).to have_http_status(:forbidden)
        expect(response.content_type).to start_with("application/json")
        expect(response.body).to include("403")
      end
    end

    context "without internal api key" do
      it "forbids action" do
        get "/api/github/#{repository.full_name}/sync", params: { api_key: create(:user).api_key }

        expect(response).to have_http_status(:forbidden)
        expect(response.content_type).to start_with("application/json")
        expect(response.body).to include("403")
      end
    end

    context "already recently synced" do
      before { repository.update!(last_synced_at: 1.hour.ago) }

      it "notifies already recently synced" do
        get "/api/github/#{repository.full_name}/sync", params: { api_key: internal_user.api_key }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to start_with("application/json")
        expect(response.body).to include("Repository has already been synced recently")
      end
    end

    context "success" do
      it "notifies the sync is queued" do
        get "/api/github/#{repository.full_name}/sync", params: { api_key: internal_user.api_key }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to start_with("application/json")
        expect(response.body).to include("Repository queued for re-sync")
      end
    end
  end
end
