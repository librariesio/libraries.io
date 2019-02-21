require 'rails_helper'

describe MaintenanceStats::Stats::ReleaseStats do
  let!(:auth_token) { create(:auth_token) }
  let(:client) { auth_token.v4_github_client }
  let(:start_date) { DateTime.parse("2018-12-14T17:49:49+00:00") }
  let(:query_klass) { MaintenanceStats::Queries::RepoReleasesQuery.new(client) }
  let(:query_params) { {owner: repository.owner_name, repo_name: repository.project_name, end_date: start_date - 365} }

  let(:stat) { described_class.new(query_results) }

  before do
    # set the value for DateTime.current so that the queries always have the same variables and can be matched in VCR
    allow(DateTime).to receive(:current).and_return(DateTime.parse("2018-12-14T17:49:49+00:00"))
  end

  context "with a valid repository" do
    let(:repository) { create(:repository) }
    let(:query_results) do
        VCR.use_cassette('github/rails_api', :match_requests_on => [:body]) do
           return query_klass.query(params: query_params)
        end
    end

    it "should have repository release stats" do
        results = stat.get_stats

        expected_keys = %W(last_release_date last_week_releases last_month_releases last_two_month_releases last_year_releases).map(&:to_sym)

        expect(results.keys).to eql expected_keys
        
        # check values against the VCR cassette data
        expect(results[:last_week_releases]).to eql 1
        expect(results[:last_month_releases]).to eql 2
        expect(results[:last_two_month_releases]).to eql 2
        expect(results[:last_year_releases]).to eql 2

        expect(results[:last_release_date]).to eql "2019-01-18T21:32:44Z"
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

        expected_keys = %W(last_release_date last_week_releases last_month_releases last_two_month_releases last_year_releases).map(&:to_sym)

        expect(results.keys).to eql expected_keys

        expect(results[:last_week_releases]).to eql 0
        expect(results[:last_month_releases]).to eql 0
        expect(results[:last_two_month_releases]).to eql 0
        expect(results[:last_year_releases]).to eql 0
        expect(results[:last_release_date]).to be nil
    end
  end
end