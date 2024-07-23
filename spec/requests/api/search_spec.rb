# frozen_string_literal: true

require "rails_helper"

describe "API::SearchController", elasticsearch: true do
  describe "GET /api/search", type: :request do
    let!(:user) { create(:user) }
    let!(:project) { create :project, name: "charisma-generator" }
    let!(:other_project) { create :project, name: "wisdom-generator" }
    let!(:version) { create(:version, project: project, number: "1.0.0") }

    context "with missing api key" do
      it "returns forbidden" do
        get "/api/search"

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an invalid api key" do
      it "returns forbidden" do
        get "/api/search?api_key=abc123"

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with valid api key" do
      before do
        Project.__elasticsearch__.refresh_index!
      end

      it "renders successfully" do
        get "/api/search", params: { api_key: user.api_key, q: "charisma" }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to start_with("application/json")
        response_hash = JSON.parse(response.body)
        expect(response_hash.size).to eq(1)
        expect(response_hash.first.keys).to include("versions")
      end

      it "renders successfully with include_versions=false" do
        get "/api/search", params: { api_key: user.api_key, q: "charisma", include_versions: false }

        expect(response.content_type).to start_with("application/json")
        response_hash = JSON.parse(response.body)
        expect(response_hash.size).to eq(1)
        expect(response_hash.first.keys).not_to include("versions")
      end
    end

    context "with pg_search_projects enabled" do
      before do
        expect_any_instance_of(ApplicationController).to receive(:use_pg_search?).and_return(true)
        allow_any_instance_of(ApplicationController).to receive(:es_query).and_raise
      end

      it "renders successfully" do
        get "/api/search", params: { api_key: user.api_key, q: "charisma" }

        expect(response.content_type).to start_with("application/json")
        response_hash = JSON.parse(response.body)
        expect(response_hash.size).to eq(1)
        expect(response_hash.first).to match(
          {
            "code_of_conduct_url" => nil,
            "contribution_guidelines_url" => nil,
            "contributions_count" => 0,
            "dependent_repos_count" => 0,
            "dependents_count" => 0,
            "deprecation_reason" => nil,
            "description" => "Ruby on Rails is a full-stack web framework optimized for programmer happiness and sustainable productivity. It encourages beautiful code by favoring convention over configuration.",
            "forks" => 0,
            "funding_urls" => nil,
            "homepage" => "http://rubyonrails.org/",
            "keywords" => ["web"],
            "language" => "Ruby",
            "latest_download_url" => "https://rubygems.org/downloads/charisma-generator-1.0.0.gem",
            "latest_release_number" => "1.0.0",
            "latest_release_published_at" => anything,
            "latest_stable_release_number" => nil,
            "latest_stable_release_published_at" => nil,
            "license_normalized" => false,
            "licenses" => "MIT",
            "name" => "charisma-generator",
            "normalized_licenses" => ["MIT"],
            "package_manager_url" => "https://rubygems.org/gems/charisma-generator",
            "platform" => "Rubygems",
            "rank" => 0,
            "repository_license" => nil,
            "repository_status" => nil,
            "repository_url" => "https://github.com/rails/charisma-generator",
            "security_policy_url" => nil,
            "stars" => 0,
            "status" => nil,
            "versions" => [
              {
                "number" => "1.0.0",
                "published_at" => anything,
                "spdx_expression" => nil,
                "original_license" => nil,
                "researched_at" => nil,
                "repository_sources" => ["Rubygems"],
              },
            ],
          }
        )
      end

      it "renders successfully with include_versions=false" do
        get "/api/search", params: { api_key: user.api_key, q: "charisma", include_versions: false }

        expect(response.content_type).to start_with("application/json")
        response_hash = JSON.parse(response.body)
        expect(response_hash.size).to eq(1)
        expect(response_hash.first.keys).not_to include("versions")
      end
    end
  end
end
