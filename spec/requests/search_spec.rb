require "rails_helper"

describe "SearchController" do
  let!(:project) { create(:project) }

  describe "GET /search", type: :request do
    it "renders successfully when logged out" do
      visit search_path
      expect(page).to have_content project.name
    end
  end
end
