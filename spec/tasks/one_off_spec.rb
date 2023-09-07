# frozen_string_literal: true

require "rails_helper"

describe "one_off" do
  describe "backfill_project_status_checked_at" do
    before { travel_to DateTime.current }

    let!(:first_to_backfill) { create(:project, name: "first_to_backfill", updated_at: 1.week.ago, status_checked_at: nil) }
    let!(:second_to_backfill) { create(:project, name: "second_to_backfill", updated_at: 2.weeks.ago, status_checked_at: nil) }
    let!(:not_to_backfill) { create(:project, name: "not_to_backfill", updated_at: 3.weeks.ago, status_checked_at: 1.day.ago) }

    it "backfills status_checked_at with updated_at value when status_checked_at is blank" do
      Rake::Task["one_off:backfill_project_status_checked_at"].invoke

      first_to_backfill.reload
      second_to_backfill.reload
      not_to_backfill.reload

      expect(first_to_backfill.status_checked_at).to eq(1.week.ago)
      expect(first_to_backfill.updated_at).to eq(1.week.ago)

      expect(second_to_backfill.status_checked_at).to eq(2.weeks.ago)
      expect(second_to_backfill.updated_at).to eq(2.weeks.ago)

      expect(not_to_backfill.status_checked_at).to eq(1.day.ago)
      expect(not_to_backfill.updated_at).to eq(3.weeks.ago)
    end
  end

  describe "correct_maven_dependencies_platforms" do
    # a project for dependencies to link to
    let(:target_project) { create(:project, platform: "Rubygems") }

    let(:non_maven_project) { create(:project, platform: "Pypi", name: "non-maven") }
    let(:non_maven_version) { create(:version, project: non_maven_project, number: "1.0.0") }
    let!(:non_maven_version_dependency) { create(:dependency, project: target_project, version: non_maven_version, platform: target_project.platform, name: target_project.name) }

    let(:maven_project1) { create(:project, platform: "Maven", name: "maven1") }
    let(:maven1_version1) { create(:version, project: maven_project1, number: "1.0.0") }
    let!(:maven1_version1_dependency1) { create(:dependency, project: target_project, version: maven1_version1, platform: "Maven", name: target_project.name) }
    let!(:maven1_version1_dependency2) { create(:dependency, project: target_project, version: maven1_version1, platform: "MavenCentral", name: target_project.name) }
    let(:maven1_version2) { create(:version, project: maven_project1, number: "2.0.0") }
    let!(:maven1_version2_dependency) { create(:dependency, project: target_project, version: maven1_version2, platform: "GoogleMaven", name: target_project.name) }

    let(:maven_project2) { create(:project, platform: "Maven", name: "maven2") }
    let(:maven2_version) { create(:version, project: maven_project2, number: "1.0.0") }
    let!(:maven2_version_dependency) { create(:dependency, project: target_project, version: maven2_version, platform: "Maven", name: target_project.name) }

    it "fixes the incorrect dependencies" do
      Rake::Task["one_off:correct_maven_dependencies_platforms"].invoke

      non_maven_version_dependency.reload
      maven1_version1_dependency1.reload
      maven1_version1_dependency2.reload
      maven1_version2_dependency.reload
      maven2_version_dependency.reload

      expect(non_maven_version_dependency.platform).to eq(target_project.platform)
      expect(maven1_version1_dependency1.platform).to eq("Maven")
      expect(maven1_version1_dependency2.platform).to eq("Maven")
      expect(maven1_version2_dependency.platform).to eq("Maven")
      expect(maven2_version_dependency.platform).to eq("Maven")
    end
  end
end
