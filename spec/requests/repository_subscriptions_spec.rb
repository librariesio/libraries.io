# frozen_string_literal: true
require "rails_helper"

describe "RepositorySubscriptionsController" do
  let(:user) { create(:user) }
  let(:repository) { create(:repository) }
  let(:repository_subscription) { create(:repository_subscription, user: user, repository: repository) }

  describe "GET /repository_subscriptions/:id/edit", type: :request do
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
