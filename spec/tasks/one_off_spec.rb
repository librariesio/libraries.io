# frozen_string_literal: true

require "rails_helper"

describe "one_off" do
  describe "backfill_project_status_checked_at" do

    before { travel_to DateTime.current }

    let!(:first_to_backfill) { create(:project, name: "first_to_backfill", updated_at: 1.week.ago, status_checked_at: nil ) }
    let!(:second_to_backfill) { create(:project, name: "second_to_backfill", updated_at: 2.weeks.ago, status_checked_at: nil ) }
    let!(:not_to_backfill) { create(:project, name: "not_to_backfill", updated_at: 3.weeks.ago, status_checked_at: 1.day.ago ) }

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

  describe "backfill kind of Pypi dependencies" do
    let(:project) { create(:project, platform: "Pypi") }
    let(:affected_version1) { create(:version, project: project)}
    let(:affected_version2) { create(:version, number: "0.1.0", project: project)}
    let(:unaffected_version) { create(:version, number: "2.0.0", project: project)}
    let(:dependency) {
      create(
        :dependency,
        version: affected_version1
      )
    }

    before do
      affected_version1.dependencies << [
        "1.2.3 ; extra == 'socks'",
        "1.2.3 ; python_version == '1.2.3'",
        "1.2.3"
      ].map do |requirements|
        create(
          :dependency,
          requirements: requirements
        )
      end

      affected_version2.dependencies << [
        "1.2.3 ; extra == 'socks'",
        "1.2.3 ; python_version == '1.2.3'",
        "1.2.3"
      ].map do |requirements|
        create(
          :dependency,
          requirements: requirements
        )
      end

      unaffected_version.dependencies << [
        create(
          :dependency,
          requirements: "1.2.4"
        )
      ]

      allow(PackageManagerDownloadWorker)
        .to receive(:perform_in)
    end

    it "backfills correctly" do
      Rake::Task["one_off:backfill_pypi_dependencies_kind"].execute

      expect(PackageManagerDownloadWorker)
        .to have_received(:perform_in)
              .with(
                0,
                "pypi",
                project.name,
                affected_version1.number,
                "pypi-kind-backfill",
                0,
                true
              )

      expect(PackageManagerDownloadWorker)
        .to have_received(:perform_in)
              .with(
                0,
                "pypi",
                project.name,
                affected_version2.number,
                "pypi-kind-backfill",
                0,
                true
              )

      expect(PackageManagerDownloadWorker)
        .to have_received(:perform_in)
              .exactly(2).times
    end
  end
end
