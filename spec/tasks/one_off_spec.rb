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
end
