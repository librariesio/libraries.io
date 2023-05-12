# frozen_string_literal: true

require "rails_helper"

describe "AccountsController" do
  let(:user) { create :user }

  describe "GET /account", type: :request do
    it "denies access when logged out" do
      get account_path
      expect(response).to redirect_to(login_path)
    end

    it "renders successfully for logged in users" do
      login(user)
      visit account_path
      expect(page).to have_content "Account"
    end
  end
end
