require "rails_helper"

describe "Api::BowerSearchController", elasticsearch: true do
  let!(:project) { create(:project, platform: 'Bower') }

  describe "GET /api/bower-search", type: :request do
    it "renders successfully" do
      Project.__elasticsearch__.refresh_index!
      get '/api/bower-search'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json')
      expect(json).to eq(
        [
          {
            dependent_repos_count: project.dependent_repos_count,
            dependents_count: project.dependents_count,
            deprecation_reason: project.deprecation_reason,
            description: project.description,
            forks: project.forks,
            homepage: project.homepage,
            keywords: project.keywords,
            language: project.language,
            latest_download_url: nil,
            latest_release_number: project.latest_release_number,
            latest_release_published_at: project.latest_release_published_at,
            latest_stable_release: project.latest_stable_release,
            latest_stable_release_number: project.latest_stable_release_number,
            latest_stable_release_published_at: project.latest_stable_release_published_at,
            license_normalized: project.license_normalized,
            licenses: project.licenses,
            name: project.name,
            normalized_licenses: project.normalized_licenses,
            package_manager_url: project.package_manager_url,
            platform: project.platform,
            rank: project.rank,
            repository_url: project.repository_url,
            stars: project.stars,
            status: project.status,
            scm_license: project.scm_license,
            versions: project.versions
          }
        ].as_json
      )
    end
  end
end
