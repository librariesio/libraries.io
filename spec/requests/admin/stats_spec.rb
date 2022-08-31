# frozen_string_literal: true
require "rails_helper"

describe "Admin::StatsController", elasticsearch: true do
  let(:user) { create :user }

  describe "GET /admin/stats", type: :request do
    it "denies access when logged out" do
      get admin_stats_path
      expect(response).to redirect_to(login_path)
    end

    it "denies access for non-admins" do
      login(user)
      expect { visit admin_stats_path }.to raise_exception ActiveRecord::RecordNotFound
    end

    it "renders successfully for admins" do
      mock_is_admin
      login(user)
      visit admin_stats_path
      expect(page).to have_content 'Recent Signups'
    end
  end

  describe "GET /admin/stats/repositories", type: :request do
    it "denies access when logged out" do
      get admin_repositories_stats_path
      expect(response).to redirect_to(login_path)
    end

    it "denies access for non-admins" do
      login(user)
      expect { visit admin_repositories_stats_path }.to raise_exception ActiveRecord::RecordNotFound
    end

    it "renders successfully for admins" do
      mock_is_admin
      login(user)
      visit admin_repositories_stats_path
      expect(page).to have_content 'Repo Stats'
    end
  end
end
