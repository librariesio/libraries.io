# frozen_string_literal: true

require "rails_helper"

RSpec.describe LanguagesController do
  let!(:project) { create(:project) }

  describe "GET #index" do
    it "responds successfully", type: :request do
      visit languages_path
      expect(page).to have_content "Languages"
    end
  end

  describe "GET #show" do
    it "responds successfully", type: :request do
      visit language_path(project.language)
      expect(page).to have_content project.language
    end
  end
end
