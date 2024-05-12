# frozen_string_literal: true

require "rails_helper"

describe "SearchController", elasticsearch: true do
  let!(:project) { create(:project) }
  let(:search_criteria) { project.name }
  let(:user) { create :user }

  describe "GET /search", type: :request do
    context "without search criteria" do
      before do
        login(user)
      end

      let(:search_criteria) { "" }

      it "renders instructions to try again" do
        Project.__elasticsearch__.refresh_index!
        visit search_path(params: { q: search_criteria })

        expect(page).not_to have_content project.name
        expect(page).to have_content "Please provide search criteria and try again"
      end
    end

    it "requires a log in to search" do
      Project.__elasticsearch__.refresh_index!
      visit search_path(params: { q: search_criteria })
      expect(page).to have_content "Login to Libraries.io"
    end
  end

  describe "GET /search.atom", type: :request do
    context "without search criteria" do
      let(:search_criteria) { "" }

      before do
        login(user)
      end

      it "renders no results" do
        Project.__elasticsearch__.refresh_index!
        visit search_path(params: { q: search_criteria })

        expect(page).not_to have_content project.name
      end
    end

    it "requires a log in to search" do
      Project.__elasticsearch__.refresh_index!
      visit search_path(params: { q: search_criteria }, format: :atom)
      expect(page).to have_content "Login to Libraries.io"
    end
  end

  context "with pg_search_projects enabled" do
    before do
      expect_any_instance_of(ApplicationController).to receive(:use_pg_search?).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:es_query).and_raise

      login(user)
    end

    it "renders results page successfully" do
      visit search_path(params: { q: search_criteria })
      expect(page).to have_content project.name
    end

    it "renders atom feed of results successfully" do
      visit search_path(params: { q: search_criteria }, format: :atom)
      expect(page).to have_content project.name
    end
  end
end
