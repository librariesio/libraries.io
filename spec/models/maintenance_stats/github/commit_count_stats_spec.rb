require 'rails_helper'

describe MaintenanceStats::Stats::Github::LastYearCommitsStat do
  let!(:auth_token) { create(:auth_token) }
  let(:client) { auth_token.v4_github_client }
  let(:query_klass) { MaintenanceStats::Queries::Github::CommitCountQuery.new(client) }
  let(:start_date) { DateTime.parse("2018-12-14T17:49:49+00:00") }
  let(:query_params) { {owner: repository.owner_name, repo_name: repository.project_name, start_date: (start_date - 365).iso8601} }

  let(:stat) { described_class.new(query_results) }

  context "with a valid repository" do
    let(:repository) { create(:repository) }
    let(:query_results) do
        VCR.use_cassette('github/rails_api', :match_requests_on => [:body]) do
           return query_klass.query(params: query_params)
        end
    end

    it "should get timed commit count stats from the results" do
        results = stat.get_stats

        expected_keys = %W(last_year_commits).map(&:to_sym)

        expect(results.keys).to eql expected_keys

        # check values against the VCR cassette data
        expect(results[:last_year_commits]).to eql 4677
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

        expected_keys = %W(last_year_commits).map(&:to_sym)

        expect(results.keys).to eql expected_keys

        # check values against the VCR cassette data
        expect(results[:last_year_commits]).to eql nil
    end
  end
end

describe MaintenanceStats::Stats::Github::V3CommitsStat do
    let!(:auth_token) { create(:auth_token) }
    let(:client) { auth_token.github_client }
    let(:query_klass) { MaintenanceStats::Queries::Github::CommitCountQueryV3.new(client) }
    let(:query_params) { {full_name: repository.full_name} }

    let(:stat) { described_class.new(query_results) }

    context "with a valid repository" do
        let(:repository) { create(:repository) }
        let(:query_results) do
            VCR.use_cassette('github/rails_api') do
                return query_klass.query(params: query_params)
            end
        end

        it "should get timed commit counts for the last year from the request" do
            results = stat.get_stats

            expected_keys = %W(v3_last_week_commits v3_last_4_weeks_commits v3_last_8_weeks_commits v3_last_52_weeks_commits).map(&:to_sym)

            expect(results.keys).to eql expected_keys

            # check values against the VCR cassette data
            expect(results[:v3_last_week_commits]).to eql 87
            expect(results[:v3_last_4_weeks_commits]).to eql 273
            expect(results[:v3_last_8_weeks_commits]).to eql 560
            expect(results[:v3_last_52_weeks_commits]).to eql 3908
        end
    end

    context "repository with no commits" do
        let(:repository) { create(:repository, full_name: 'buddhamagnet/heidigoodchild') }
        let(:query_results) do
            VCR.use_cassette('github/empty_repository') do
                return query_klass.query(params: query_params)
            end
        end

        it "should handle no data from query" do
            results = stat.get_stats

            expected_keys = %W(v3_last_week_commits v3_last_4_weeks_commits v3_last_8_weeks_commits v3_last_52_weeks_commits).map(&:to_sym)

            expect(results.keys).to eql expected_keys

            # check values against the VCR cassette data
            expect(results[:v3_last_week_commits]).to be 0
            expect(results[:v3_last_4_weeks_commits]).to be 0
            expect(results[:v3_last_8_weeks_commits]).to be 0
            expect(results[:v3_last_52_weeks_commits]).to be 0
        end
    end
end
