# frozen_string_literal: true

require "rails_helper"

describe "TreeController" do
  let(:project) { create(:project) }
  let!(:version) { create(:version, project: project) }

  describe "GET /:platform/:project/tree", type: :request do
    it "renders successfully when logged out" do
      visit tree_path(project.to_param)
      expect(page).to have_content "Dependency Tree"
    end
  end

  describe "GET /:platform/:project/:version/tree", type: :request do
    it "renders successfully when logged out" do
      visit version_tree_path(version.to_param)
      expect(page).to have_content "Dependency Tree"
    end
  end
end
