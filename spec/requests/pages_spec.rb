require "rails_helper"

describe "PagesController", :vcr do
  describe "GET /about", type: :request do
    it "renders successfully when logged out" do
      visit about_path
      expect(page).to have_content 'What is Libraries.io?'
    end
  end
end
