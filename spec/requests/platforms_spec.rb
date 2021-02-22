# frozen_string_literal: true
require "rails_helper"

RSpec.describe PlatformsController do
  let!(:project) { create(:project) }

  describe "GET #index" do
    it "responds successfully", type: :request do
      visit platforms_path
      expect(page).to have_content 'Platforms'
    end
  end

  describe "GET #show" do
    it "responds successfully", type: :request do
      visit platform_path(project.platform)
      expect(page).to have_content project.platform
    end
  end
end
