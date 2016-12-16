require "rails_helper"

describe "API::DocController" do
  describe "GET /api/", :vcr, type: :request do
    it "renders successfully" do
      project = create(:project, name: 'base62', platform: 'NPM')
      create(:version, project: project)
      create(:github_repository, full_name: 'gruntjs/grunt')
      create(:github_user)

      visit '/api'
      expect(page).to have_content 'API Docs'
    end
  end
end
