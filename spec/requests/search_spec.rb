require "rails_helper"

describe "SearchController", :vcr do
  before :each do
    @project = create(:project)
    Project.__elasticsearch__.import force: true
    Project.__elasticsearch__.refresh_index!
  end

  describe "GET /search", type: :request do
    it "renders successfully when logged out" do
      visit search_path
      expect(page).to have_content @project.name
    end
  end
end
