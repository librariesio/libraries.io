# frozen_string_literal: true

require "rails_helper"

describe "Api::ProjectsController" do
  let!(:user) { create(:user) }
  let!(:project) { create(:project, name: "foo.bar@baz:bah,name") }
  let!(:dependent_project) { create(:project) }
  let!(:version) { create(:version, project: project, repository_sources: ["Rubygems"]) }
  let!(:dependent_version) { create(:version, project: dependent_project) }
  let!(:dependency) { create(:dependency, version: version, project: dependent_project) }
  let!(:internal_user) { create(:user) }

  before :each do
    internal_user.current_api_key.update_attribute(:is_internal, true)
    project.reload
    dependent_project.reload
  end

  describe "GET /api/:platform/:name", type: :request do
    it "renders successfully" do
      get "/api/#{project.platform}/#{project.name}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to be_json_eql project_json_response(project).to_json
    end

    it "renders successfully with internal API key" do
      get "/api/#{project.platform}/#{project.name}?api_key=#{internal_user.api_key}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")

      # with internal API key we add updated_at field
      expected_response = project_json_response(project)
      expected_response[:updated_at] = project.updated_at.iso8601(3)
      expect(response.body).to be_json_eql expected_response.to_json
    end
  end

  # Disabled for performance reasons
  xdescribe "GET /api/:platform/:name/dependents", type: :request do
    it "renders successfully" do
      get "/api/#{dependent_project.platform}/#{dependent_project.name}/dependents"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to be_json_eql [project_json_response(project)].to_json
    end

    it "renders name only" do
      get "/api/#{dependent_project.platform}/#{dependent_project.name}/dependents?subset=name_only"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to be_json_eql [{ name: project.name }].to_json
    end
  end

  describe "GET /api/:platform/:name/dependent_repositories", type: :request do
    it "renders successfully" do
      get "/api/#{project.platform}/#{project.name}/dependent_repositories"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to be_json_eql []
    end
  end

  describe "GET /api/projects/updated", type: :request do
    it "renders successfully" do
      get "/api/projects/updated?start_time=#{1.year.ago.utc.iso8601}&api_key=#{internal_user.api_key}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to be_json_eql ({
        updated: [
          {
            platform: project.platform,
            name: project.name,
            updated_at: project.updated_at.utc.iso8601(3),
          },
          {
            platform: dependent_project.platform,
            name: dependent_project.name,
            updated_at: dependent_project.updated_at.utc.iso8601(3),
          },
        ],
        deleted: [],
      }).to_json
    end

    it "ignores stuff after end_time" do
      get "/api/projects/updated?start_time=#{1.year.ago.utc.iso8601}&end_time=#{1.month.ago.utc.iso8601}&api_key=#{internal_user.api_key}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to be_json_eql ({
        updated: [],
        deleted: [],
      }).to_json
    end

    it "ignores stuff before start_time" do
      after_everything = [project.updated_at, dependent_project.updated_at].max + 1
      get "/api/projects/updated?start_time=#{after_everything.utc.iso8601}&api_key=#{internal_user.api_key}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to be_json_eql ({
        updated: [],
        deleted: [],
      }).to_json
    end

    it "errors if no start_time" do
      expect { get "/api/projects/updated?api_key=#{internal_user.api_key}" }
        .to raise_exception(ActionController::ParameterMissing)
    end

    it "errors if api_key is not internal" do
      expect { get "/api/projects/updated?api_key=#{user.api_key}" }
        .to raise_exception(ActionController::BadRequest)
    end

    it "errors if start_time is garbage" do
      expect { get "/api/projects/updated?start_time=NOTADATE&api_key=#{internal_user.api_key}" }
        .to raise_exception(ArgumentError)
    end

    it "errors if end_time is garbage" do
      expect { get "/api/projects/updated?start_time=#{1.year.ago.utc.iso8601}&end_time=NOTADATE&api_key=#{internal_user.api_key}" }
        .to raise_exception(ArgumentError)
    end

    it "notices deletions" do
      deleted_digest = DeletedProject.digest_from_platform_and_name(project.platform, project.name)
      project.destroy!
      get "/api/projects/updated?start_time=#{1.year.ago.utc.iso8601}&api_key=#{internal_user.api_key}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to be_json_eql ({
        updated: [
          {
            platform: dependent_project.platform,
            name: dependent_project.name,
            updated_at: dependent_project.updated_at.utc.iso8601(3),
          },
        ],
        deleted: [
          {
            digest: deleted_digest,
            updated_at: DeletedProject.first.updated_at.utc.iso8601(3),
          },
        ],
      }).to_json
    end
  end

  describe "GET /api/:platform/:name/dependencies", type: :request do
    it "renders successfully" do
      get "/api/#{project.platform}/#{project.name}/#{version.number}/dependencies"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to be_json_eql(
        {
          contributions_count: 0,
          dependencies_for_version: version.number,
          dependent_repos_count: project.dependent_repos_count,
          dependents_count: project.dependents_count,
          deprecation_reason: project.deprecation_reason,
          dependencies: version.dependencies.map do |dependency|
            {
              project_name: dependency.name,
              name: dependency.name,
              platform: dependency.platform,
              requirements: dependency.requirements,
              latest_stable: dependency.latest_stable,
              latest: dependency.latest,
              deprecated: dependency.deprecated,
              outdated: dependency.outdated,
              filepath: dependency.filepath,
              kind: dependency.kind,
              optional: dependency.optional,
              normalized_licenses: dependency.project.normalized_licenses,
            }
          end,
          description: project.description,
          forks: project.forks,
          homepage: project.homepage,
          keywords: project.keywords,
          language: project.language,
          latest_download_url: project.latest_download_url,
          latest_release_number: project.latest_release_number,
          latest_release_published_at: project.latest_release_published_at,
          latest_stable_release_number: project.latest_stable_release_number,
          latest_stable_release_published_at: project.latest_stable_release_published_at,
          license_normalized: project.license_normalized,
          licenses: project.licenses,
          name: project.name,
          normalized_licenses: project.normalized_licenses,
          package_manager_url: project.package_manager_url,
          platform: project.platform,
          rank: project.rank,
          repository_license: project.repository_license,
          repository_status: project.repository_status,
          repository_url: project.repository_url,
          stars: project.stars,
          status: project.status,
          versions: project.versions.as_json(only: %i[number original_license published_at spdx_expression researched_at repository_sources]),
        }.to_json
      )
    end
  end

  describe "GET /api/:platform/:name/dependencies?subset=minimum", type: :request do
    it "renders successfully" do
      get "/api/#{project.platform}/#{project.name}/#{version.number}/dependencies?subset=minimum"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to be_json_eql({
        "name": project.name,
        "platform": project.platform,
        "dependencies_for_version": version.number,
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
            "kind": dependency.kind,
            "optional": dependency.optional,
            "normalized_licenses": dependency.project.normalized_licenses,
          }
        end,
      }.to_json)
    end
  end

  describe "POST /api/projects/dependencies", type: :request do
    it "renders successfully" do
      post "/api/projects/dependencies", params: {
        api_key: user.api_key,
        subset: "minimum",
        projects: [
               { name: project.name,
                 platform: project.platform,
                 version: version.number },
               # supposed to lowercase name/platform when needed,
               # and omit version to use latest
               { name: project.name.upcase,
                 platform: project.platform.upcase },
               # 404 on platform
               { name: "nope",
                 platform: "unplatform" },
               # 404 on name
               { name: "noooooo",
                 platform: "rubygems" },
],
      }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to be_json_eql([
        { status: 200,
          body: {
            "name": project.name,
            "platform": project.platform,
            "dependencies_for_version": version.number,
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
                "kind": dependency.kind,
                "optional": dependency.optional,
                "normalized_licenses": dependency.project.normalized_licenses,
              }
            end,
          } },
        { status: 200,
          body: {
            "name": project.name,
            "platform": project.platform,
            "dependencies_for_version": version.number,
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
                "kind": dependency.kind,
                "optional": dependency.optional,
                "normalized_licenses": dependency.project.normalized_licenses,
              }
            end,
          } },
        { status: 404,
          body: {
            "error": "Error 404, project or project version not found.",
            "name": "nope",
            "platform": "unplatform",
            "dependencies_for_version": "latest",
          } },
        { status: 404,
          body: {
            "error": "Error 404, project or project version not found.",
            "name": "noooooo",
            "platform": "rubygems",
            "dependencies_for_version": "latest",
          } },
        ].to_json)
    end
  end

  describe "GET /api/:platform/:name/contributors", type: :request do
    it "renders successfully" do
      get "/api/#{project.platform}/#{project.name}/contributors"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to be_json_eql([].to_json)
    end
  end

  describe "GET /api/:platform/:name/sourcerank", type: :request do
    it "renders successfully" do
      get "/api/#{project.platform}/#{project.name}/sourcerank"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/json")
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
        "versions_present": 0,
      }.to_json)
    end
  end

  context "for a Go project that is not in the DB" do
    let!(:project) { create(:project, platform: "Go", name: "known/project") }

    context "that redirects to a known project" do
      it "redirects" do
        allow(PackageManager::Go)
          .to receive(:project_find_names)
          .with("unknown/project")
          .and_return([project.name])

        get "/api/go/unknown%2Fproject/contributors"
        expect(response).to redirect_to("/api/go/known%2Fproject/contributors")
      end
    end

    context "that redirects to an unknown project" do
      it "redirects" do
        allow(PackageManager::Go)
          .to receive(:project_find_names)
          .with("unknown/project")
          .and_return(["other/unknown/project"])

        expect { get "/api/go/unknown%2Fproject/contributors" }
          .to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "that does not redirect" do
      it "returns not found" do
        allow(PackageManager::Go)
          .to receive(:project_find_names)
          .with("unknown/project")
          .and_return(["unknown/project"])

        expect { get "/api/go/unknown%2Fproject/contributors" }
          .to raise_exception(ActiveRecord::RecordNotFound)
      end
    end
  end
end
