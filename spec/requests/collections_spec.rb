require "rails_helper"

describe "CollectionController", :vcr do
  before :each do
    @project = create(:project)
    Project.__elasticsearch__.import force: true
    Project.__elasticsearch__.refresh_index!
  end

  describe "GET /collections", type: :request do
    it "renders successfully when logged out" do
      visit collections_path
      expect(page).to have_content 'Explore'
    end
  end

  describe "GET /explore/:language-:keyword-libraries", type: :request do
    it "renders successfully when logged out" do
      visit collection_path(@project.language, @project.keywords.first)
      expect(page).to have_content 'libraries written in'
    end
  end
end
