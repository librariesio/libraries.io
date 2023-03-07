# frozen_string_literal: true

require "rails_helper"

describe "maintenance stats" do
  describe "gather_maintenance_stats" do
    let(:repository) { create(:repository, full_name: "chalk/chalk") }
    let!(:auth_token) { create(:auth_token) }
    let!(:project) do
      repository.projects.create!(
        name: "test-project",
        platform: "Maven",
        repository_url: "https://github.com/librariesio/libraries.io",
        homepage: "https://libraries.io"
      )
    end

    before do
      # set the value for DateTime.current so that the queries always have the same variables and can be matched in VCR
      allow(DateTime).to receive(:current).and_return(DateTime.parse("2018-12-14T17:49:49+00:00"))
    end

    let!(:tempfile) do
      Tempfile.new(["temp", ".csv"]).tap do |file|
        CSV.open(file, "wb", col_sep: "\t") do |csv|
          csv << %w[maven test-project]
        end
      end
    end

    it "gathers mtaintenance stats from a list of project platforms and names" do
      expect do
        VCR.use_cassette("github/chalk_api", match_requests_on: %i[method uri body query]) do
          Rake::Task["maintenance_stats:gather_maintenance_stats"].invoke(tempfile.path, "yes")
        end
      end.to change(RepositoryMaintenanceStat, :count).from(0).to(23)
    end
  end
end
