# frozen_string_literal: true

require "rails_helper"
require "query_counter"

describe "API::StatusController" do
  let(:url) { "/api/check" }
  let(:internal_user) { create(:user) }
  let(:normal_user) { create(:user) }
  let!(:repository) { create(:repository) }
  let!(:maintenance_stat) { create(:repository_maintenance_stat, repository: repository) }
  let!(:project) { create(:project, repository: repository) }
  let!(:project_django) { create(:project, name: "Django", platform: "Pypi", keywords: "old kewords", keywords_array: ["new keywords"]) }

  before do
    internal_user.current_api_key.update_attribute(:is_internal, true)
  end

  describe "POST /api/check", type: :request do
    it "renders successfully with one" do
      post url, params: { api_key: internal_user.api_key, projects: [{ name: project.name, platform: project.platform }] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(response.body.include?(project.name)).to be == true

      # check for maintenance stats being returned
      json_response = JSON.parse(response.body)
      maintenance_stats = json_response.first["repository_maintenance_stats"]
      expect(maintenance_stats.length).to be 1
      expect(maintenance_stats.first["category"]).to eql maintenance_stat.category
      expect(maintenance_stats.first["value"]).to eql maintenance_stat.value

      # and updated_at
      updated_at = json_response.first["updated_at"]
      expect(updated_at).not_to be(nil)
    end

    it "renders empty json list if cannot find Project" do
      post url, params: { api_key: internal_user.api_key, projects: [{ name: "rails", platform: "rubygems" }] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(response.body).to be_json_eql []
    end

    it "renders successfully" do
      post url, params: { api_key: internal_user.api_key, projects: [{ name: project.name, platform: "rubygems" }, { name: "django", platform: "Pypi" }] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(response.body.include?(project.name)).to be == true
      expect(response.body.include?("Django")).to be == true
    end

    it "renders empty maintenance stats if they don't exist" do
      post url, params: { api_key: internal_user.api_key, projects: [{ name: project_django.name, platform: project_django.platform }] }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")
      expect(response.body.include?(project_django.name)).to be == true

      json_response = JSON.parse(response.body)
      expect(json_response.first["repository_maintenance_stats"].length).to be 0
    end

    it "contains all expected fields" do
      # all the fields we expect to come back in the response for a project
      expected_fields = %w[
        canonical_name
        dependent_repos_count
        dependents_count
        description
        forks
        homepage
        keywords
        language
        latest_download_url
        latest_release_number
        latest_release_published_at
        latest_stable_release_number
        latest_stable_release_published_at
        name
        normalized_licenses
        package_manager_url
        platform
        rank
        repository_maintenance_stats
        repository_url
        score
        stars
        status
        versions
      ]

      post(
        url,
        params: {
          api_key: internal_user.api_key,
          projects: [{ name: project_django.name, platform: project_django.platform }],
          score: true,
        }
      )
      expect(response).to have_http_status(:success)
      expect(response.content_type).to start_with("application/json")

      project = JSON.parse(response.body).first
      expected_fields.each do |field|
        expect(project).to have_key(field)
      end
    end

    it "correctly serves the keywords array" do
      post(
        url,
        params: {
          api_key: internal_user.api_key,
          projects: [
            { name: project_django.name, platform: project_django.platform },
          ],
          score: true,
        }
      )

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).dig(0, "keywords")).to eq(["new keywords"])
    end

    it "correctly serves the original name" do
      requested_name = project_django.name.downcase

      post(
        url,
        params: {
          api_key: internal_user.api_key,
          projects: [
            { name: requested_name, platform: project_django.platform },
          ],
          score: true,
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
        url,
        params: {
          api_key: internal_user.api_key,
          projects: [
            { name: requested_name, platform: project.platform },
          ],
          score: true,
        }
      )

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).dig(0, "name")).to eq(requested_name)
      expect(JSON.parse(response.body).dig(0, "canonical_name")).to eq(project.name)
    end

    context "with normal API key" do
      it "returns no maintenance stats or updated_at" do
        post url, params: { api_key: normal_user.api_key, projects: [{ name: project_django.name, platform: project_django.platform }] }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to start_with("application/json")
        expect(response.body.include?(project_django.name)).to be == true

        json_response = JSON.parse(response.body)
        expect(json_response.first.key?("repository_maintenance_stats")).to be false
        expect(json_response.first.key?("updated_at")).to be false
      end
    end

    context "with two projects that have the same name but different platforms" do
      it "returns both" do
        create(:project, platform: "NPM", name: "bcrypt")
        create(:project, platform: "Pypi", name: "bcrypt")

        post(
          url,
          params: {
            api_key: internal_user.api_key,
            projects: [
              { name: "bcrypt", platform: "npm" },
              { name: "bcrypt", platform: "pypi" },
            ],
          }
        )

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json.size).to eq(2)
        expect(json.select { |p| p[:name] == "bcrypt" && p[:platform] == "NPM" }).to be
        expect(json.select { |p| p[:name] == "bcrypt" && p[:platform] == "Pypi" }).to be
      end
    end

    xit "is performant with a bunch of projects" do
      names = 10.times.map { Faker::Name.name.parameterize }.uniq

      names.each do |name|
        repository = create(:repository, full_name: name)
        project = create(:project, platform: "Rubygems", name: name, repository: repository)
        create_list(:repository_maintenance_stat, 10, repository: repository)
        10.times do |i|
          create(:version, project: project, number: "1.0.#{i}", published_at: 1.year.ago + i.days)
        end
      end

      puts Benchmark.measure {
        count = QueryCounter.count do
          post url, params: { api_key: internal_user.api_key, projects: names.map { |n| { name: n, platform: "rubygems" } } }
        end
        puts "====================\nQUERY COUNT: #{count}\n===================="
      }
    end
  end
end
