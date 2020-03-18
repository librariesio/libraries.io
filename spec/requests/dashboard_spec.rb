# frozen_string_literal: true

require "rails_helper"

describe "DashboardController" do
  let(:user) { create(:user) }

  describe "GET /dashboard", type: :request do
    it "redirects to /repositories" do
      get "/dashboard"
      expect(response).to redirect_to(repositories_path)
    end
  end

  describe "GET /muted", type: :request do
    it "renders successfully when logged in" do
      login(user)
      visit muted_path
      expect(page).to have_content "Muted Packages"
    end
  end

  describe "GET /home", type: :request do
    it "redirects to /" do
      get "/home"
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /repositories", type: :request do
    it "renders successfully when logged in" do
      login(user)
      visit repositories_path
      expect(page).to have_content "Repository Monitoring"
    end
  end

  describe "POST /unwatch/:repository_id", type: :request do
    it "redirects to /repositories" do
      repository = create(:repository)
      create(:repository_subscription, repository: repository, user: user)

      login(user)
      rack_test_session_wrapper = Capybara.current_session.driver
      rack_test_session_wrapper.submit :post, unwatch_path(repository.id), nil

      expect(page.current_path).to eq "/"
    end
  end
end
