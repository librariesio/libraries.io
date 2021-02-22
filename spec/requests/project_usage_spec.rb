# frozen_string_literal: true
require "rails_helper"

describe "ProjectUsageController" do
  let(:project) { create(:project) }

  describe "GET renders successfully when logged in", type: :request do
    it "renders successfully when logged in" do
      visit project_usage_path(project.to_param)
      expect(page).to have_content 'Usage stats for'
    end
  end
end
