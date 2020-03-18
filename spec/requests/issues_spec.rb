# frozen_string_literal: true

require "rails_helper"

describe "IssuesController", elasticsearch: true do
  let!(:issue) { create(:issue) }

  describe "GET /help-wanted", type: :request do
    it "renders successfully when logged out" do
      Issue.__elasticsearch__.refresh_index!
      visit help_wanted_path
      expect(page).to have_content "Help Wanted"
    end
  end

  describe "GET /first-pull-request", type: :request do
    it "renders successfully when logged out" do
      Issue.__elasticsearch__.refresh_index!
      visit first_pull_request_path
      expect(page).to have_content "First Pull Request"
    end
  end

  describe "GET /github/issues", type: :request do
    it "renders successfully when logged out" do
      visit issues_path
      expect(page).to have_content "Issues"
    end
  end

  describe "GET /github/issues/your-dependencies", type: :request do
    it "renders successfully when logged in" do
      Issue.__elasticsearch__.refresh_index!
      user = create(:user)
      login(user)
      visit your_dependencies_issues_path
      expect(page).to have_content "Issues on Your Dependencies"
    end
  end
end
