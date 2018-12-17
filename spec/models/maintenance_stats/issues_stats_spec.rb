require 'rails_helper'

describe MaintenanceStats::IssueRates do
  let!(:auth_token) { create(:auth_token) }
  let(:client) { AuthToken.v4_client }
  let(:query_klass) { MaintenanceStats::FullRepoQuery.new(client) }
  let(:query_params) { {owner: repository.owner_name, repo_name: repository.project_name} }

  let(:stat) { described_class.new(query_results) }

  context "with a valid repository" do
    let(:repository) { create(:repository) }
    let(:query_results) do
        VCR.use_cassette('github/rails_api', :match_requests_on => [:body]) do
           return query_klass.query(params: query_params)
        end
    end

    it "should have all issue stats" do
        results = stat.get_stats

        expected_keys = %W(issue_closure_rate closed_issue_count open_issue_count).map(&:to_sym)

        expect(results.keys).to eql expected_keys
        
        # check values against the VCR cassette data
        expect(results[:closed_issue_count]).to eql 11784
        expect(results[:open_issue_count]).to eql 335

        expected_closure_rate = (results[:closed_issue_count] * 100.0) / stat.total_issues_count
        expect(results[:issue_closure_rate]).to eql expected_closure_rate
    end
  end
  
  context "repository with no commits" do
    let(:repository) { create(:repository, full_name: 'buddhamagnet/heidigoodchild') }
    let(:query_results) do
        VCR.use_cassette('github/empty_repository', :match_requests_on => [:body]) do
           return query_klass.query(params: query_params)
        end
    end

    it "should handle no data from query" do
        results = stat.get_stats

        expected_keys = %W(issue_closure_rate closed_issue_count open_issue_count).map(&:to_sym)

        expect(results.keys).to eql expected_keys

        expect(results[:closed_issue_count]).to eql 0
        expect(results[:open_issue_count]).to eql 0
        expect(results[:issue_closure_rate]).to eql 100.0
    end
  end
end