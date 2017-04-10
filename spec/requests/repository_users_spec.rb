require "rails_helper"

describe "UsersController" do
  let(:repository_user) { create(:repository_user) }
  let(:repository_organisation) { create(:repository_organisation) }

  describe "GET /github/:login", type: :request do
    it "renders successfully when logged out" do
      visit user_path(repository_user.to_param)
      expect(page).to have_content repository_user.name
    end

    it "renders orgs successfully when logged out" do
      visit user_path(repository_organisation.to_param)
      expect(page).to have_content repository_organisation.name
    end
  end
end
