# frozen_string_literal: true

require "rails_helper"

RSpec.describe KeywordsController do
  let!(:project) { create(:project) }

  describe "GET #index" do
    it "responds successfully", type: :request do
      visit keywords_path
      expect(page).to have_content "Keywords"
    end
  end

  describe "GET #show" do
    it "responds successfully", type: :request do
      visit keyword_path(project.keywords.first)
      expect(page).to have_content project.keywords.first
    end
  end
end
