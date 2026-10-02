# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectsController do
  let!(:project) { create(:project, platform: "Rubygems", name: "super_package") }
  let!(:version) { create(:version, project: project) }
  let!(:dependency) { create(:dependency, version: version) }

  describe "GET #index" do
    it "responds successfully", type: :request do
      visit root_path
      expect(page).to have_content "Libraries.io"
    end
  end

  describe "GET #show" do
    it "responds successfully", type: :request do
      visit project_path(project.to_param)
      expect(page).to have_content project.name
    end

    context "with authenticated user" do
      let(:user) { create(:user) }

      it "responds successfully" do
        login(user)
        visit project_path(project.to_param)
        expect(page).to have_content project.name
      end
    end
  end

  describe "GET #show for a version" do
    it "redirects to login when not authenticated" do
      visit version_path(version.to_param)
      expect(page).to have_content "You must be logged in to view this content."
    end

    it "responds successfully when authenticated" do
      login(create(:user))
      visit version_path(version.to_param)
      expect(page).to have_content project.name
    end
  end

  describe "GET #sourcerank" do
    it "responds successfully", type: :request do
      visit project_sourcerank_path(project.to_param)
      expect(page).to have_content project.name
    end
  end

  describe "GET #about" do
    it "responds successfully", type: :request do
      visit project_path(project.to_param.merge(format: "about"))
      expect(page).to have_content project.name
    end
  end

  describe "GET #dependents" do
    it "responds successfully", type: :request do
      visit project_dependents_path(project.to_param)
      expect(page).to have_content project.name
    end
  end

  describe "GET #dependent_repos" do
    it "responds successfully", type: :request do
      visit project_dependent_repos_path(project.to_param)
      expect(page).to have_content project.name
    end
  end

  describe "GET #versions" do
    it "responds successfully", type: :request do
      visit project_versions_path(project.to_param)
      expect(page).to have_content project.name
    end
  end

  describe "GET #tags" do
    it "responds successfully", type: :request do
      visit project_tags_path(project.to_param)
      expect(page).to have_content project.name
    end
  end
end
