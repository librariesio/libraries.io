require 'rails_helper'

describe MaintenanceStats::Stats::PullRequestRates do
  let!(:auth_token) { create(:auth_token) }
  let(:client) { auth_token.v4_github_client }
  let(:query_klass) { MaintenanceStats::Queries::FullRepoQuery.new(client) }
  let(:query_params) { {owner: repository.owner_name, repo_name: repository.project_name} }

  let(:stat) { described_class.new(query_results) }

  context "with a valid repository" do
    let(:repository) { create(:repository) }
    let(:query_results) do
        VCR.use_cassette('github/rails_api', :match_requests_on => [:body]) do
           return query_klass.query(params: query_params)
        end
    end

    it "should have pull request stats" do
        results = stat.get_stats

        expected_keys = %W(pull_request_acceptance closed_pull_request_count open_pull_request_count merged_pull_request_count).map(&:to_sym)

        expect(results.keys).to eql expected_keys
        
        # check values against the VCR cassette data
        expect(results[:closed_pull_request_count]).to eql 7045
        expect(results[:open_pull_request_count]).to eql 700
        expect(results[:merged_pull_request_count]).to eql 14765

        expected_acceptance_rate = results[:merged_pull_request_count].to_f/ stat.total_pull_requests_count.to_f
        expect(results[:pull_request_acceptance]).to eql expected_acceptance_rate
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

        expected_keys = %W(pull_request_acceptance closed_pull_request_count open_pull_request_count merged_pull_request_count).map(&:to_sym)

        expect(results.keys).to eql expected_keys

        expect(results[:closed_pull_request_count]).to eql 0
        expect(results[:open_pull_request_count]).to eql 0
        expect(results[:merged_pull_request_count]).to eql 0
        expect(results[:pull_request_acceptance]).to eql 1.0
    end
  end
end