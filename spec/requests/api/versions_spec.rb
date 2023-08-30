# frozen_string_literal: true

require "rails_helper"

describe "Api::RepositoriesController" do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  # Make a handful of versions offsetting each one by 5 minutes
  def make_versions(proj, count)
    count.times.map do |i|
      offset = i + 1
      updated_at = Time.now - ((count - offset) * 5.minutes)
      create(:version, project: proj, number: "#{offset}.0.0", updated_at: updated_at)
    end
  end

  it "fails for non-internal user" do
    get "/api/versions", params: { since: Time.now.iso8601, api_key: user.api_key }
    expect(response).to have_http_status(:forbidden)
  end

  context "with an internal user" do
    before(:each) do
      freeze_time
    end

    let(:user) { create(:user, :internal) }

    it "returns useful data for a version" do
      version = make_versions(project, 1)[0]
      get "/api/versions", params: { since: 1.day.ago, api_key: user.api_key }

      expect(response).to have_http_status(:success)
      expect(json["results"].first["coordinate"]).to match("rubygems/#{version.project.name.downcase}/1.0.0")
      expect(json["results"].first.keys).to match_array %w[coordinate original_license updated_at published_at spdx_expression status]
      expect(json["more"]).to eq 0
    end

    it "returns versions since a provided date/time" do
      versions = make_versions(project, 5)

      get "/api/versions", params: { since: versions[2].updated_at.iso8601, api_key: user.api_key }

      expect(response).to have_http_status(:success)
      expected_coords = versions[3..4].map { |v| Coordinate.generate(v.project, v.number) }
      expect(json["results"].pluck("coordinate")).to match_array expected_coords
      expect(json["more"]).to eq 0
    end

    it "notes if there are more results to retrieve" do
      make_versions(project, 2)

      get "/api/versions", params: { since: 1.day.ago, api_key: user.api_key, max_results: 1 }

      expect(response).to have_http_status(:success)
      expect(json["more"]).to eq 1
    end

    it "only fetches versions that have a project" do
      versions_with_project = make_versions(project, 2)
      version_without_project = create(:version, project: create(:project), number: "1.0.0", updated_at: 1.second.ago)
      version_without_project.project.destroy!

      get "/api/versions", params: { since: 1.year.ago, api_key: user.api_key }

      expect(response).to have_http_status(:success)
      expected_coords = versions_with_project.map { |v| Coordinate.generate(v.project, v.number) }
      expect(json["results"].pluck("coordinate")).to match_array expected_coords
      expect(json["more"]).to eq 0
    end
  end
end
