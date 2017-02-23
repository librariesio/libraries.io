require "rails_helper"

describe "PagesController", :vcr do
  describe "GET /about", type: :request do
    it "renders successfully when logged out" do
      visit about_path
      expect(page).to have_content 'About'
    end
  end
  describe "GET /packagemanagercompatibility", type: :request do
    it "renders successfully when logged out" do
      visit pmmatrix_path
      expect(page).to have_content 'Package Manager Compatibility Matrix'
    end
  end
end
