# frozen_string_literal: true

require "rails_helper"

describe "PagesController" do
  describe "GET /about", type: :request do
    it "renders successfully when logged out" do
      visit about_path
      expect(page).to have_content "About"
    end
  end
  describe "GET /packagemanagercompatibility", type: :request do
    it "renders successfully when logged out" do
      visit compatibility_path
      expect(page).to have_content "Package Manager Compatibility Matrix"
    end
  end
  describe "GET /team", type: :request do
    it "renders successfully when logged out" do
      visit team_path
      expect(page).to have_content "Team"
    end
  end
end
