require "rails_helper"

RSpec.describe PlatformsController, :vcr do
  before :each do
    Repositories::Rubygems::URL
    @project = create(:project)
    Project.__elasticsearch__.import force: true
    Project.__elasticsearch__.refresh_index!
  end

  describe "GET #index" do
    it "responds successfully", type: :request do
      visit platforms_path
      expect(page).to have_content 'Platforms'
    end
  end

  describe "GET #show" do
    it "responds successfully", type: :request do
      visit platform_path(@project.platform)
      expect(page).to have_content  @project.platform
    end
  end
end
