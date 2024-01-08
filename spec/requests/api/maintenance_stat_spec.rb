# frozen_string_literal: true

require "rails_helper"

describe "API::MaintenanceStatsController" do
  let(:internal_user) { create(:user) }
  let(:normal_user) { create(:user) }

  before do
    internal_user.current_api_key.update_attribute(:is_internal, true)
  end

  describe "POST /api/maintenance/stats/begin/bulk", type: :request do
    let!(:repository) { create(:repository) }
    let!(:repository_django) { create(:repository, full_name: "django/django") }
    let!(:project) { create(:project, repository: repository) }
    let!(:project_django) { create(:project, name: "Django", platform: "Pypi", repository: repository_django) }

    it "begins watching projects" do
      expect(RepositoryMaintenanceStatWorker).to receive(:enqueue).with(repository_django.id, priority: :high).exactly(1).times
      expect(RepositoryMaintenanceStatWorker).to receive(:enqueue).with(repository.id, priority: :high).exactly(1).times

      post(
        "/api/maintenance/stats/begin/bulk",
        params: {
          api_key: internal_user.api_key,
          projects: [
            { name: project_django.name.downcase, platform: project_django.platform },
            { name: project.name.downcase, platform: project.platform },
          ],
        }
      )

      expect(response).to have_http_status(:success)
    end

    it "skips projects with stats" do
      create(:repository_maintenance_stat, repository: repository)
      expect(RepositoryMaintenanceStatWorker).to receive(:enqueue).with(repository_django.id, priority: :high).exactly(1).times
      expect(RepositoryMaintenanceStatWorker).to receive(:enqueue).with(repository.id, priority: :high).exactly(0).times

      post(
        "/api/maintenance/stats/begin/bulk",
        params: {
          api_key: internal_user.api_key,
          projects: [
            { name: project_django.name.downcase, platform: project_django.platform },
            { name: project.name.downcase, platform: project.platform },
          ],
        }
      )

      expect(response).to have_http_status(:success)
    end

    context "with normal API key" do
      it "returns no maintenance stats" do
        post(
          "/api/maintenance/stats/begin/bulk",
          params: {
            api_key: normal_user.api_key,
            projects: [
              { name: project_django.name.downcase, platform: project_django.platform },
              { name: project.name.downcase, platform: project.platform },
            ],
          }
        )
        expect(response).to have_http_status(403)
      end
    end
  end

  describe "POST /api/maintenance/stats/begin/repositories", type: :request do
    let!(:auth_token) { create(:auth_token, token: "test_token") }

    before do
      allow(RepositoryMaintenanceStatWorker).to receive(:enqueue)
    end

    it "creates a new repository and begins watching" do
      expect(Repository.count).to eql(0)

      VCR.use_cassette("github/chalk_api", match_requests_on: %i[method uri body query]) do
        post(
          "/api/maintenance/stats/begin/repositories",
          params: {
            api_key: internal_user.api_key,
            repositories: [
              { host_type: "GitHub", full_name: "chalk/chalk" },
            ],
          }
        )
      end

      expect(Repository.count).to eql(1)
      repository = Repository.first
      expect(RepositoryMaintenanceStatWorker).to have_received(:enqueue).with(repository.id, priority: :medium)
      expect(response).to have_http_status(:accepted)
    end

    context "with existing repositories" do
      let!(:repository_gitlab) { create(:repository, host_type: "GitLab", full_name: "baserow/baserow") }
      let!(:repository_github) { create(:repository, host_type: "GitHub", full_name: "chalk/chalk") }

      it "finds existing repo and beings watching" do
        VCR.use_cassette("github/chalk_api", match_requests_on: %i[method uri body query]) do
          post(
            "/api/maintenance/stats/begin/repositories",
            params: {
              api_key: internal_user.api_key,
              repositories: [
                { host_type: repository_github.host_type, full_name: repository_github.full_name },
              ],
            }
          )
        end

        expect(RepositoryMaintenanceStatWorker).to have_received(:enqueue).with(repository_github.id, priority: :medium)
        expect(response).to have_http_status(:accepted)
      end

      it "does not update stats for unsupported repository host" do
        VCR.use_cassette("github/chalk_api", match_requests_on: %i[method uri body query]) do
          post(
            "/api/maintenance/stats/begin/repositories",
            params: {
              api_key: internal_user.api_key,
              repositories: [
                { host_type: repository_gitlab.host_type, full_name: repository_gitlab.full_name },
              ],
            }
          )
        end

        expect(RepositoryMaintenanceStatWorker).not_to have_received(:enqueue).with(repository_github.id, priority: :medium)
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eql("#{repository_gitlab.host_type} is not a supported host")
      end

      context "with existing stats" do
        let!(:stat) { create(:repository_maintenance_stat, repository: repository_github) }

        it "find existing repo with stats and skips it" do
          VCR.use_cassette("github/chalk_api", match_requests_on: %i[method uri body query]) do
            post(
              "/api/maintenance/stats/begin/repositories",
              params: {
                api_key: internal_user.api_key,
                repositories: [
                  { host_type: repository_github.host_type, full_name: repository_github.full_name },
                ],
              }
            )
          end

          expect(RepositoryMaintenanceStatWorker).not_to have_received(:enqueue).with(repository_github.id, priority: :medium)
          expect(response).to have_http_status(:accepted)
        end
      end

      it "ignores invalid repo names" do
        VCR.use_cassette("github/chalk_api", match_requests_on: %i[method uri body query]) do
          post(
            "/api/maintenance/stats/begin/repositories",
            params: {
              api_key: internal_user.api_key,
              repositories: [
                { host_type: repository_github.host_type, full_name: "invalid" },
              ],
            }
          )
        end

        expect(RepositoryMaintenanceStatWorker).not_to have_received(:enqueue)
        expect(response).to have_http_status(:accepted)
      end
    end

    context "with normal API key" do
      it "returns no maintenance stats" do
        post(
          "/api/maintenance/stats/begin/repositories",
          params: {
            api_key: normal_user.api_key,
            repositories: [
              { host_type: "GitHub", full_name: "whatever" },
            ],
          }
        )
        expect(response).to have_http_status(403)
      end
    end
  end
end
