# frozen_string_literal: true

require "rails_helper"

describe "projects" do
  describe "check_status" do
    context "with projects" do
      let(:never_checked) { create(:project, name: "never_checked", platform: "Rubygems", status_checked_at: nil ) }
      let(:checked_a_year_ago) { create(:project, name: "checked_a_year_ago", platform: "Rubygems", status_checked_at: 1.year.ago ) }
      let(:checked_a_year_ago_invalid_platform) { create(:project, name: "checked_a_year_ago_invalid_platform", platform: "InvalidPlatform", status_checked_at: 1.year.ago ) }
      let(:checked_a_month_ago) { create(:project, name: "checked_a_month_ago", platform: "Rubygems", status_checked_at: 1.month.ago ) }
      let(:checked_a_day_ago) { create(:project, name: "checked_a_day_ago", platform: "Rubygems", status_checked_at: 1.day.ago ) }

      before do
        travel_to DateTime.current

        # We already test Project#check_status web functionality in spec/models/project_spec.rb
        # So here just mock the response to verify the function is otherwise called correctly
        [never_checked, checked_a_year_ago, checked_a_year_ago_invalid_platform, checked_a_month_ago, checked_a_day_ago].each do |project|
          WebMock.stub_request(:get, PackageManager::Rubygems.check_status_url(project)).to_return(status: 200)
        end
      end

      after(:each) do
        Rake::Task["projects:check_status"].reenable
      end

      it "checks status of correct projects" do
        Sidekiq::Testing.inline! do
          Rake::Task["projects:check_status"].invoke
        end

        never_checked.reload
        checked_a_year_ago.reload
        checked_a_year_ago_invalid_platform.reload
        checked_a_month_ago.reload
        checked_a_day_ago.reload

        # Checks status of projects that have never been checked
        # or have been checked more than a week ago
        expect(never_checked.status_checked_at).to eq(DateTime.current)
        expect(checked_a_year_ago.status_checked_at).to eq(DateTime.current)
        expect(checked_a_month_ago.status_checked_at).to eq(DateTime.current)

        # Does not check status of projects with platforms not to
        # checked, or that have been checked recently
        expect(checked_a_year_ago_invalid_platform.status_checked_at).to eq(1.year.ago)
        expect(checked_a_day_ago.status_checked_at).to eq(1.day.ago)
      end

      it "correctly prioritizes projects to check when given a maximum" do
        Sidekiq::Testing.inline! do
          # Only check status of 2 projects with batch size of 1
          Rake::Task["projects:check_status"].invoke(2, 1)
        end

        never_checked.reload
        checked_a_year_ago.reload
        checked_a_year_ago_invalid_platform.reload
        checked_a_month_ago.reload
        checked_a_day_ago.reload

        # Checks status of projects that have never been checked
        # or have been checked more than a week ago, prioritizing
        # nils and older
        expect(never_checked.status_checked_at).to eq(DateTime.current)
        expect(checked_a_year_ago.status_checked_at).to eq(DateTime.current)

        # Does not check status of projects past the maximum
        expect(checked_a_month_ago.status_checked_at).to eq(1.month.ago)

        # Does not check status of projects with platforms not to
        # checked, or that have been checked recently
        expect(checked_a_year_ago_invalid_platform.status_checked_at).to eq(1.year.ago)
        expect(checked_a_day_ago.status_checked_at).to eq(1.day.ago)
      end
    end
  end
end
