require "rails_helper"

describe "CollectionController", elasticsearch: true do
  let!(:project) { create(:project) }

  describe "GET /collections", type: :request do
    it "renders successfully when logged out" do
      visit collections_path
      expect(page).to have_content 'Explore'
    end
  end

  describe "GET /explore/:language-:keyword-libraries", type: :request do
    it "renders successfully when logged out" do
      Project.__elasticsearch__.refresh_index!
      visit collection_path(project.language, project.keywords.first)
      expect(page).to have_content 'packages written in'
    end
  end
end
