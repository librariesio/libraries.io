require "rails_helper"

describe "Api::ProjectsController" do
  let!(:project) { create(:project) }
  let!(:dependent_project) { create(:project) }
  let!(:version) { create(:version, project: project) }
  let!(:dependent_version) { create(:version, project: dependent_project) }
  let!(:dependency) { create(:dependency, version: version, project: dependent_project) }

  before :each do
    project.reload
    dependent_project.reload
  end

  describe "GET /api/:platform/:name", type: :request do
    it "renders successfully" do
      get "/api/#{project.platform}/#{project.name}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql project_json_response(project).to_json
    end
  end

  describe "GET /api/:platform/:name/dependents", type: :request do
    it "renders successfully" do
      get "/api/#{dependent_project.platform}/#{dependent_project.name}/dependents"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql [project_json_response(project)].to_json
    end
  end

  describe "GET /api/:platform/:name/dependent_repositories", type: :request do
    it "renders successfully" do
      get "/api/#{project.platform}/#{project.name}/dependent_repositories"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql []
    end
  end

  describe "GET /api/searchcode", type: :request do
    it "renders successfully" do
      get "/api/searchcode"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql [project.repository_url, dependent_project.repository_url].to_json
    end
  end

  describe "GET /api/:platform/:name/dependencies", type: :request do
    it "renders successfully" do
      get "/api/#{project.platform}/#{project.name}/#{version.number}/dependencies"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql({
        "name": project.name,
        "platform": project.platform,
        "description": project.description,
        "homepage": project.homepage,
        "repository_url": project.repository_url,
        "normalized_licenses": project.normalized_licenses,
        "rank": project.rank,
        "latest_release_published_at": project.latest_release_published_at,
        "latest_release_number": project.latest_release_number,
        "language": project.language,
        "status": project.status,
        "package_manager_url": project.package_manager_url,
        "stars": project.stars,
        "forks": project.forks,
        "keywords": project.keywords,
        "latest_stable_release": project.latest_stable_release,
        "versions": project.versions.as_json(only: [:number, :published_at]),
        "dependencies": version.dependencies.map do |dependency|
          {
          "project_name": dependency.name,
          "name": dependency.name,
          "platform": dependency.platform,
          "requirements": dependency.requirements,
          "latest_stable": dependency.latest_stable,
          "latest": dependency.latest,
          "deprecated": dependency.deprecated,
          "outdated": dependency.outdated,
          "filepath": dependency.filepath,
          "kind": dependency.kind
          }
        end
        }.to_json)
    end
  end

  describe "GET /api/:platform/:name/contributors", type: :request do
    it "renders successfully" do
      get "/api/#{project.platform}/#{project.name}/contributors"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql([].to_json)
    end
  end
end
