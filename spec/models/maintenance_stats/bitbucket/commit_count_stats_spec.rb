# frozen_string_literal: true
require 'rails_helper'

describe MaintenanceStats::Stats::Bitbucket::CommitsStat do
  context "with bitbucket repository" do
    let(:repository) { create(:repository, full_name:'ecollins/passlib', host_type: 'Bitbucket') }
    let!(:auth_token) { create(:auth_token) }
    let!(:project) do
      repository.projects.create!(
        name: 'test-project',
        platform: 'Pypi',
        repository_url: 'https://bitbucket.org/ecollins/passlib',
        homepage: 'https://libraries.io'
      )
    end

    it "should return commit data" do
      VCR.use_cassette('bitbucket/passlib') do
        commits = repository.retrieve_commits

        stats = described_class.new(commits).get_stats

        expected_keys = [:last_week_commits, :last_month_commits, :last_two_month_commits, :last_year_commits, :latest_commit]

        expect(stats.keys).to eql expected_keys

        # check values against the VCR cassette data
        expect(stats[:latest_commit]).to eql Date.new(2017,6,6)
      end
    end
  end
end