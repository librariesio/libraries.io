require "rails_helper"

describe "Api::BowerSearchController", elasticsearch: true do
  let!(:project) { create(:project, platform: 'Bower') }

  describe "GET /api/bower-search", type: :request do
    it "renders successfully" do
      Project.__elasticsearch__.refresh_index!
      get '/api/bower-search'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json).to eq [{
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
        "versions": project.versions
        }].as_json
    end
  end
end
