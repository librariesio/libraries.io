require 'rails_helper'

describe MaintenanceStats::Stats::Github::V3IssueStats do
  let!(:auth_token) { create(:auth_token) }
  let(:client) { AuthToken.client }
  let(:query_klass) { MaintenanceStats::Queries::IssuesQuery.new(client) }
  let(:query_params) { {full_name: "vuejs/vue", since: "2018-12-14T17:49:49Z"} }

  let(:stat) { described_class.new(query_results) }

  context "with a valid repository" do
    let(:repository) { create(:repository) }
    let(:query_results) do
        VCR.use_cassette('github/vue') do
           return query_klass.query(params: query_params)
        end
    end

    it "should include issue and pull request stats" do
      results = stat.get_stats

      expected_keys = %W(one_year_open_issues one_year_closed_issues one_year_total_issues one_year_issue_closure_rate one_year_open_pull_requests one_year_closed_pull_requests one_year_total_pull_requests one_year_pull_request_closure_rate issues_stats_truncated).map(&:to_sym)

      expect(results.keys).to eql expected_keys
    end

    it "should have all issue stats" do
        results = stat.get_stats
        
        # check values against the VCR cassette data
        expect(results[:one_year_open_issues]).to eql 53
        expect(results[:one_year_closed_issues]).to eql 363
        expect(results[:one_year_total_issues]).to eql 416

        expected_closure_rate = results[:one_year_closed_issues].to_f / results[:one_year_total_issues].to_f
        expect(results[:one_year_issue_closure_rate]).to eql expected_closure_rate
    end

    it "should have all pull request stats" do
      results = stat.get_stats

      # check values against the VCR cassette data
      expect(results[:one_year_open_pull_requests]).to eql 47
      expect(results[:one_year_closed_pull_requests]).to eql 92
      expect(results[:one_year_total_pull_requests]).to eql 139

      expected_closure_rate = results[:one_year_closed_pull_requests].to_f / results[:one_year_total_pull_requests].to_f
      expect(results[:one_year_pull_request_closure_rate]).to eql expected_closure_rate
    end
  end
  
  context "repository with no commits" do
    let(:repository) { create(:repository, full_name: 'buddhamagnet/heidigoodchild') }
    let(:query_params) { {full_name: "buddhamagnet/heidigoodchild", since: "2018-02-20T14:44:36Z"} }

    let(:query_results) do
        VCR.use_cassette('github/empty_repository') do
           return query_klass.query(params: query_params)
        end
    end

    it "should handle no data from query" do
        results = stat.get_stats

        expected_keys = %W(one_year_open_issues one_year_closed_issues one_year_total_issues one_year_issue_closure_rate one_year_open_pull_requests one_year_closed_pull_requests one_year_total_pull_requests one_year_pull_request_closure_rate issues_stats_truncated).map(&:to_sym)

        expect(results.keys).to eql expected_keys

        expect(results[:one_year_open_issues]).to eql 0
        expect(results[:one_year_closed_issues]).to eql 0
        expect(results[:one_year_total_issues]).to eql 0
        expect(results[:one_year_issue_closure_rate]).to eql 1.0

        expect(results[:one_year_open_pull_requests]).to eql 0
        expect(results[:one_year_closed_pull_requests]).to eql 0
        expect(results[:one_year_total_pull_requests]).to eql 0
        expect(results[:one_year_pull_request_closure_rate]).to eql 1.0

        expect(results[:issues_stats_truncated]).to eql false
    end
  end
end