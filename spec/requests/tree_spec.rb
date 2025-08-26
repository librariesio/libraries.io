# frozen_string_literal: true

require "rails_helper"

describe "TreeController" do
  let(:project) { create(:project) }
  let!(:version) { create(:version, project: project) }
  let(:user) { create :user }

  before do
    login(user)
  end

  describe "GET /:platform/:project/tree", type: :request do
    it "renders successfully" do
      visit tree_path(project.to_param)
      expect(page).to have_content "Dependency Tree"
    end
  end

  describe "GET /:platform/:project/:number/tree", type: :request do
    it "renders successfully" do
      visit version_tree_path(version.to_param)
      expect(page).to have_content "Dependency Tree"
    end
  end
end
