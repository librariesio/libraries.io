# frozen_string_literal: true

require "rails_helper"

describe "SearchController", elasticsearch: true do
  let!(:project) { create(:project) }
  let(:search_term) { project.name }

  describe "GET /search", type: :request do
    context "without a search term" do
      let(:search_term) { "" }

      it "renders instructions to try again" do
        Project.__elasticsearch__.refresh_index!
        visit search_path(params: { q: search_term })

        expect(page).not_to have_content project.name
        expect(page).to have_content "Please provide a search term and try again"
      end
    end

    it "renders successfully when logged out" do
      Project.__elasticsearch__.refresh_index!
      visit search_path(params: { q: search_term })
      expect(page).to have_content project.name
    end
  end

  describe "GET /search.atom", type: :request do
    context "without a search term" do
      let(:search_term) { "" }

      it "renders no results" do
        Project.__elasticsearch__.refresh_index!
        visit search_path(params: { q: search_term })

        expect(page).not_to have_content project.name
      end
    end

    it "renders successfully when logged out" do
      Project.__elasticsearch__.refresh_index!
      visit search_path(params: { q: search_term }, format: :atom)
      expect(page).to have_content project.name
    end
  end
end
