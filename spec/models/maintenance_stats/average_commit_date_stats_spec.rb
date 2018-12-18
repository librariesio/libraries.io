require 'rails_helper'

describe MaintenanceStats::AverageCommitDate do
  let!(:auth_token) { create(:auth_token) }
  let(:client) { auth_token.v4_github_client }
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

    it "should get an average commit date from the results" do
        results = stat.get_stats

        expect(results.key?(:average_commit_date)).to be true
        # this will be the average pulled from the VCR cassette
        expected_date = Time.parse("2018-09-26 10:05:07 GMT").utc
        expect(results[:average_commit_date]).to eql expected_date
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

        expect(results.key?(:average_commit_date)).to be true
        # no data should return a nil
        expect(results[:average_commit_date]).to eql nil
    end
  end
end