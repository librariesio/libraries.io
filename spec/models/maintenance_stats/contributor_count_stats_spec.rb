require 'rails_helper'

describe MaintenanceStats::Stats::V3ContributorCountStats do
  let!(:auth_token) { create(:auth_token) }
  let(:client) { AuthToken.client }
  let(:query_klass) { MaintenanceStats::Queries::RepositoryContributorStatsQuery.new(client) }
  let(:query_params) { {full_name: "vuejs/vue"} }

  let(:stat) { described_class.new(query_results) }

  context "with a valid repository" do
    let(:repository) { create(:repository) }
    let(:query_results) do
      VCR.use_cassette('github/vue') do
        return query_klass.query(params: query_params)
      end
    end

    it "should get timed contributor counts for the last year from the request" do
      results = stat.get_stats

      expected_keys = %W(v3_last_week_contributors v3_last_4_weeks_contributors v3_last_8_weeks_contributors v3_last_52_weeks_contributors).map(&:to_sym)

      expect(results.keys).to eql expected_keys

      # check values against the VCR cassette data
      expect(results[:v3_last_week_contributors]).to eql 1
      expect(results[:v3_last_4_weeks_contributors]).to eql 4
      expect(results[:v3_last_8_weeks_contributors]).to eql 13
      expect(results[:v3_last_52_weeks_contributors]).to eql 31
    end
  end

  context "repository with no contributors" do
    let(:repository) { create(:repository, full_name: 'librariesio/gem_parser') }
    let(:query_results) do
      VCR.use_cassette('github/gem_parser') do
        return query_klass.query(params: {full_name: "librariesio/gem_parser"})
      end
    end

    it "should handle no data from query" do
      results = stat.get_stats

      expected_keys = %W(v3_last_week_contributors v3_last_4_weeks_contributors v3_last_8_weeks_contributors v3_last_52_weeks_contributors).map(&:to_sym)

      expect(results.keys).to eql expected_keys

      # check values against the VCR cassette data
      expect(results[:v3_last_week_contributors]).to be 0
      expect(results[:v3_last_4_weeks_contributors]).to be 0
      expect(results[:v3_last_8_weeks_contributors]).to be 0
      expect(results[:v3_last_52_weeks_contributors]).to be 0
    end
  end
end
