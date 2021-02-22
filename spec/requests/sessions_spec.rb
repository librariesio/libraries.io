# frozen_string_literal: true
require "rails_helper"

describe "SessionsController" do
  describe "GET /login", type: :request do
    it "redirects to github" do
      visit login_path
      expect(page).to have_content 'Login to Libraries.io'
    end
  end

  describe "GET /enable_public", type: :request do
    it "redirects to github" do
      get enable_public_path
      expect(response).to redirect_to('/auth/github_public')
    end
  end

  describe "GET /enable_private", type: :request do
    it "redirects to github" do
      get enable_private_path
      expect(response).to redirect_to('/auth/github_private')
    end
  end

  describe "GET /logout", type: :request do
    it "redirects to root" do
      get logout_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /auth/failure", type: :request do
    it "redirects to root" do
      post '/auth/failure'
      expect(response).to redirect_to(root_path)
    end
  end
end
