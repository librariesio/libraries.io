require "rails_helper"

describe "RecommendationsController" do
  let(:user) { create(:user) }

  describe "GET /recommendations renders successfully when logged in", type: :request do
    it "denies access when logged out" do
      get recommendations_path
      expect(response).to redirect_to(login_path)
    end

    it "renders successfully when logged in" do
      login(user)
      visit recommendations_path
      expect(page).to have_content 'Recommended Packages'
    end
  end
end
