require "rails_helper"

describe "UsersController", :vcr do
  let(:github_user) { create(:github_user) }
  let(:github_organisation) { create(:github_organisation) }

  describe "GET /github/:login", type: :request do
    it "renders successfully when logged out" do
      visit user_path(github_user)
      expect(page).to have_content github_user.login
    end

    it "renders orgs successfully when logged out" do
      visit user_path(github_organisation)
      expect(page).to have_content github_organisation.login
    end
  end
end
