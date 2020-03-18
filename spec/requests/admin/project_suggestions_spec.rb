# frozen_string_literal: true

require "rails_helper"

describe "Admin::ProjectSuggestionsController" do
  let(:user) { create :user }

  describe "GET /admin/project_suggestions", type: :request do
    it "denies access when logged out" do
      get admin_project_suggestions_path
      expect(response).to redirect_to(login_path)
    end

    it "denies access for non-admins" do
      login(user)
      expect { visit admin_project_suggestions_path }.to raise_exception ActiveRecord::RecordNotFound
    end

    it "renders successfully for admins" do
      mock_is_admin
      login(user)
      visit admin_project_suggestions_path
      expect(page).to have_content "Project Suggestions"
    end
  end
end
