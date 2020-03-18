# frozen_string_literal: true

require "rails_helper"

describe "ExploreController" do
  describe "GET /github/organisations", type: :request do
    it "renders successfully when logged out" do
      visit repository_organisations_path
      expect(page).to have_content "Organisations"
    end
  end
end
