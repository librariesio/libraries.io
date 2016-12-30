require "rails_helper"

describe "RepositorySubscriptionsController" do
  let(:user) { create(:user) }
  let(:github_repository) { create(:github_repository) }
  let(:repository_subscription) { create(:repository_subscription, user: user, github_repository: github_repository) }

  describe "GET /repository_subscriptions/:id/edit", type: :request, vcr: true do
    it "redirects to /login if not logged in" do
      get edit_repository_subscription_path(repository_subscription)
      expect(response).to redirect_to(login_path)
    end

    it "renders successfully if logged in" do
      login(user)
      visit edit_repository_subscription_path(repository_subscription)
      expect(page).to have_content 'Monitoring settings'
    end
  end
end
