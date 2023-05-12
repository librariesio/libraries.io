# frozen_string_literal: true

require "rails_helper"

describe "SessionsController" do
  describe "GET /login", type: :request do
    it "redirects to github" do
      visit login_path
      expect(page).to have_content "Login to Libraries.io"
    end
  end

  describe "GET /enable_public", type: :request do
    it "redirects to github" do
      get enable_public_path
      expect(response).to redirect_to("/auth/github_public")
    end
  end

  describe "GET /enable_private", type: :request do
    it "redirects to github" do
      get enable_private_path
      expect(response).to redirect_to("/auth/github_private")
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
      post "/auth/failure"
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /auth/:provider/callback", type: :request do
    context "with a return_to param" do
      before do
        allow(Identity).to receive(:find_with_omniauth).and_return(create(:identity))
        allow_any_instance_of(Identity).to receive(:update_from_auth_hash).and_return(true)
        allow_any_instance_of(ActionDispatch::Request::Session).to receive(:delete).and_call_original
        allow_any_instance_of(ActionDispatch::Request::Session).to receive(:delete).with(:pre_login_destination).and_return(return_to)
      end

      context "external" do
        let(:return_to) { "https://an.external.url/bad" }
        it "redirects to root" do
          post "/auth/github/callback"
          expect(response).to redirect_to(root_path)
        end
      end

      context "internal (absolute)" do
        let(:return_to) { root_url(foo: "bar") }
        it "redirects to return_to" do
          post "/auth/github/callback"
          expect(response).to redirect_to(return_to)
        end
      end

      context "internal (relative)" do
        let(:return_to) { root_path(foo: "bar") }
        it "redirects to return_to" do
          post "/auth/github/callback"
          expect(response).to redirect_to(return_to)
        end
      end
    end
  end
end
