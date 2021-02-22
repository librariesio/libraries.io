# frozen_string_literal: true
require "rails_helper"

describe "ProjectSuggestionsController" do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  describe "GET /:platform/:name/suggestions", type: :request do
    it "redirects to /login" do
      get project_suggestions_path(project.to_param)
      expect(response).to redirect_to(login_path)
    end
  end

  describe "GET renders successfully when logged in", type: :request do
    it "renders successfully when logged in" do
      login(user)
      visit project_suggestions_path(project.to_param)
      expect(page).to have_content 'Add/Update data for'
    end
  end

  describe "POST /:platform/:name/suggestions", type: :request do
    it "redirects to /:platform/:name" do
      login(user)
      rack_test_session_wrapper = Capybara.current_session.driver
      rack_test_session_wrapper.submit :post, project_suggestions_path(project.to_param), {project_suggestion: {license: 'MIT', notes: 'From LICENSE file'}}

      expect(page.current_path).to eq project_path(project.to_param)
    end
  end
end
