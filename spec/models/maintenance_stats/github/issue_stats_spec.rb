# frozen_string_literal: true

require "rails_helper"

describe MaintenanceStats::Stats::Github::IssueStats do
  let!(:auth_token) { create(:auth_token) }
  let(:client) { auth_token.v4_github_client }
  let(:start_date) { DateTime.parse("2018-12-14T17:49:49+00:00") }
  let(:query_klass) { MaintenanceStats::Queries::Github::IssuesQuery.new(client) }
  let(:query_params) { { owner: repository.owner_name, repo_name: repository.project_name, start_date: start_date } }

  let(:stat) { described_class.new(query_results) }

  before do
    # set the value for DateTime.current so that the queries always have the same variables and can be matched in VCR
    allow(DateTime).to receive(:current).and_return(DateTime.parse("2018-12-14T17:49:49+00:00"))
  end

  context "with a valid repository" do
    let(:repository) { create(:repository, full_name: "chalk/chalk") }
    let(:query_results) do
      VCR.use_cassette("github/chalk_api", match_requests_on: %i[method uri body query]) do
        return query_klass.query(params: query_params)
      end
    end

    it "should have repository maintenance stats" do
      results = stat.fetch_stats

      expected_keys = %i[one_year_open_issues
                         one_year_closed_issues
                         one_year_total_issues
                         one_year_issue_closure_rate
                         one_year_open_pull_requests
                         one_year_closed_pull_requests
                         one_year_total_pull_requests
                         one_year_pull_request_closure_rate
                         issues_stats_truncated]

      expect(results.keys).to eql expected_keys

      # check values against the VCR cassette data
      expect(results[:one_year_open_issues]).to eql 3
      expect(results[:one_year_closed_issues]).to eql 195
    end
  end

  context "repository with no commits" do
    let(:repository) { create(:repository, full_name: "buddhamagnet/heidigoodchild") }
    let(:query_results) do
      VCR.use_cassette("github/empty_repository", match_requests_on: %i[method uri body query]) do
        return query_klass.query(params: query_params)
      end
    end

    it "should handle no data from query" do
      results = stat.fetch_stats

      expect(results).to be {}
    end
  end
end
