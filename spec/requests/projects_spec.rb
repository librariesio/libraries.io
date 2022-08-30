# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectsController do
  let!(:project) { create(:project) }
  let!(:version) { create(:version, project: project) }
  let!(:dependency) { create(:dependency, version: version) }

  describe "GET #index" do
    it "responds successfully", type: :request do
      visit root_path
      expect(page).to have_content 'Libraries.io'
    end
  end

  describe "GET #show" do
    it "responds successfully", type: :request do
      visit project_path(project.to_param)
      expect(page).to have_content project.name
    end
  end

  describe "GET #score" do
    it "responds successfully", type: :request do
      visit project_score_path(project.to_param)
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
      visit project_path(project.to_param.merge(format: 'about'))
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
