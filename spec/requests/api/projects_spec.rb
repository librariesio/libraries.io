require "rails_helper"

describe "Api::ProjectsController" do
  let!(:project) { create(:project, name: 'foo.bar@baz:bah,name') }
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

  describe "GET /api/:platform/:name/sourcerank", type: :request do
    it "renders successfully" do
      get "/api/#{project.platform}/#{project.name}/sourcerank"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(response.body).to be_json_eql({
       "all_prereleases": 0,
       "any_outdated_dependencies": 0,
       "basic_info_present": 1,
       "contributors": 0,
       "dependent_projects": 0,
       "dependent_repositories": 0,
       "follows_semver": 1,
       "is_deprecated": 0,
       "is_removed": 0,
       "is_unmaintained": 0,
       "license_present": 1,
       "not_brand_new": 0,
       "one_point_oh": 1,
       "readme_present": 0,
       "recent_release": 1,
       "repository_present": 0,
       "stars": 0,
       "subscribers": 0,
       "versions_present": 0}.to_json)
    end
  end
end
