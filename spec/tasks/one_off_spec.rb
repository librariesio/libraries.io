# frozen_string_literal: true

require "rails_helper"
require "rake"

describe "one_off rake tasks" do
  Rails.application.load_tasks

  describe "dedupe_repository_maintenance_stats" do
    let(:repository) { create(:repository) }

    before do
      travel_to Time.now

      create_list(:repository_maintenance_stat, 3, category: "foo", repository: repository) do |rms, i|
        rms.update!(updated_at: (i+1).days.ago)
      end

      create_list(:repository_maintenance_stat, 2, category: "bar", repository: repository) do |rms, i|
        rms.update!(updated_at: (i+1).days.ago)
      end
    end

    it "dedupes correctly" do
      expect do
        Rake::Task["one_off:dedupe_repository_maintenance_stats"].execute
      end.to change(RepositoryMaintenanceStat, :count)
               .from(5).to(2)

      expect(RepositoryMaintenanceStat.all).to all(have_attributes(updated_at: 1.days.ago))
    end
  end
end
