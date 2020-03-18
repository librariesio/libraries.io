# frozen_string_literal: true

require "rails_helper"

RSpec.describe LicensesController do
  let!(:project) { create(:project) }

  describe "GET #index" do
    it "responds successfully", type: :request do
      visit licenses_path
      expect(page).to have_content "Licenses"
    end
  end

  describe "GET #show" do
    it "responds successfully", type: :request do
      visit license_path(project.normalize_licenses.first)
      expect(page).to have_content project.normalize_licenses.first
    end
  end
end
