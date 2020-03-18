# frozen_string_literal: true

require "rails_helper"

describe "SubscriptionsController" do
  let(:user) { create :user }

  describe "GET /subscriptions", type: :request do
    it "denies access when logged out" do
      get subscriptions_path
      expect(response).to redirect_to(login_path)
    end

    it "renders successfully for logged in users" do
      login(user)
      visit subscriptions_path
      expect(page).to have_content "Subscriptions"
    end
  end
end
