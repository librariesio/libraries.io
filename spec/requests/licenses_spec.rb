require "rails_helper"

RSpec.describe LicensesController, :vcr do
  before :each do
    @project = create(:project)
    Project.__elasticsearch__.import force: true
    Project.__elasticsearch__.refresh_index!
  end

  describe "GET #index" do
    it "responds successfully", type: :request do
      visit licenses_path
      expect(page).to have_content 'Licenses'
    end
  end

  describe "GET #show" do
    it "responds successfully", type: :request do
      visit license_path(@project.normalize_licenses.first)
      expect(page).to have_content @project.normalize_licenses.first
    end
  end
end
