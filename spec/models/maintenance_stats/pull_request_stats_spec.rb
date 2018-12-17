require 'rails_helper'

describe MaintenanceStats::PullRequestRates do
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

    it "should have pull request stats" do
        results = stat.get_stats

        expected_keys = %W(pull_request_acceptance closed_pull_request_count open_pull_request_count merged_pull_request_count).map(&:to_sym)

        expect(results.keys).to eql expected_keys
        
        # check values against the VCR cassette data
        expect(results[:closed_pull_request_count]).to eql 7041
        expect(results[:open_pull_request_count]).to eql 692
        expect(results[:merged_pull_request_count]).to eql 14757

        expected_acceptance_rate = (results[:merged_pull_request_count] * 100.0) / stat.total_pull_requests_count
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
        expect(results[:pull_request_acceptance]).to eql 100.0
    end
  end
end