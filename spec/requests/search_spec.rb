# frozen_string_literal: true
require "rails_helper"

describe "SearchController", elasticsearch: true do
  let!(:project) { create(:project) }

  describe "GET /search", type: :request do
    it "renders successfully when logged out" do
      Project.__elasticsearch__.refresh_index!
      visit search_path
      expect(page).to have_content project.name
    end
  end

  describe "GET /search.atom", type: :request do
    it "renders successfully when logged out" do
      Project.__elasticsearch__.refresh_index!
      visit search_path(format: :atom)
      expect(page).to have_content project.name
    end
  end
end
