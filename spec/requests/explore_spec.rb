require "rails_helper"

describe "ExploreController", elasticsearch: true do
  describe "GET /explore", type: :request do
    it "renders successfully when logged out" do
      visit explore_path
      expect(page).to have_content 'Explore'
    end
  end
end
