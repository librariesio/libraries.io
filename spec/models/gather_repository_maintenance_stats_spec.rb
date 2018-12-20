require 'rails_helper'

describe GatherRepositoryMaintenanceStats do
  let(:repository) { create(:repository) }
  let!(:auth_token) { create(:auth_token) }

  before do
    # set the value for DateTime.current so that the queries always have the same variables and can be matched in VCR
    allow(DateTime).to receive(:current).and_return(DateTime.parse("2018-12-14T17:49:49+00:00"))
  end

  describe "#gather_stats" do
      context "with a valid repository" do
        before do
          VCR.use_cassette('github/rails_api', :match_requests_on => [:method, :uri, :body]) do
            GatherRepositoryMaintenanceStats.gather_stats(repository)
          end
        end

        it "should save metrics for repository" do
          maintenance_stats = repository.repository_maintenance_stats
          expect(maintenance_stats.count).to be > 0

          maintenance_stats.each do |stat|
            # every stat should have a value
            expect(stat.value).to_not be nil
          end
        end

        it "should update existing stats" do
          first_updated_at = repository.repository_maintenance_stats.first.updated_at
          category = repository.repository_maintenance_stats.first.category

          VCR.use_cassette('github/rails_api', :match_requests_on => [:method, :uri, :body]) do
            GatherRepositoryMaintenanceStats.gather_stats(repository)
          end

          updated_stat = repository.repository_maintenance_stats.find_by(category: category)
          expect(updated_stat).to_not be nil
          expect(updated_stat.updated_at).to be > first_updated_at
        end
      end

      context "with invalid repository" do
        let(:repository) { create(:repository, full_name: 'bad/example-for-testing') }

        it "should save metrics for repository" do
          VCR.use_cassette('github/bad_repository', :match_requests_on => [:method, :uri, :body]) do
            GatherRepositoryMaintenanceStats.gather_stats(repository)
          end

          maintenance_stats = repository.repository_maintenance_stats
          expect(maintenance_stats.count).to be 0
        end
      end

      context "with empty repository" do
        let(:repository) { create(:repository, full_name: 'buddhamagnet/heidigoodchild') }

        it "should save default values" do
          VCR.use_cassette('github/empty_repository', :match_requests_on => [:method, :uri, :body]) do
            GatherRepositoryMaintenanceStats.gather_stats(repository)
          end

          maintenance_stats = repository.repository_maintenance_stats
          non_zeros = {
            issue_closure_rate: "1.0",
            pull_request_acceptance: "1.0"
          }
          expect(maintenance_stats.count).to be > 0
          maintenance_stats.each do |stat|
            should_be = non_zeros.fetch(stat.category.to_sym, "0")
            expect(stat.value).to eql should_be
          end
        end
      end

      context "with non GitHub repository" do
        let(:repository) { create(:repository, host_type: "Bitbucket") }

        it "should not save any values" do
          VCR.use_cassette('github/rails_api', :match_requests_on => [:method, :uri, :body]) do
            GatherRepositoryMaintenanceStats.gather_stats(repository)
          end

          maintenance_stats = repository.repository_maintenance_stats
          expect(maintenance_stats.count).to be 0
        end
      end
  end
end

