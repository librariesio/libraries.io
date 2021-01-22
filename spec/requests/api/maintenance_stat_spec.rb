require "rails_helper"

describe "API::MaintenanceStatsController" do
  let(:internal_user) { create(:user) }
  let(:normal_user) { create(:user) }
  let!(:repository) { create(:repository) }
  let!(:repository_django) { create(:repository, full_name: 'django/django') }
  let!(:project) { create(:project, repository: repository) }
  let!(:project_django) { create(:project, name: 'Django', platform: 'Pypi', repository: repository_django) }

  before do
    internal_user.current_api_key.update_attribute(:is_internal, true)
  end

  describe "POST /api/maintenance/stats/begin/bulk", type: :request do
    it "begins watching projects" do
      expect(RepositoryMaintenanceStatWorker).to receive(:perform_async).with(repository_django.id).exactly(1).times
      expect(RepositoryMaintenanceStatWorker).to receive(:perform_async).with(repository.id).exactly(1).times

      post(
        "/api/maintenance/stats/begin/bulk",
        params: {
          api_key: internal_user.api_key,
          projects: [
            { name: project_django.name.downcase, platform: project_django.platform },
            { name: project.name.downcase, platform: project.platform }
          ]
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
            { name: project.name.downcase, platform: project.platform }
          ]
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
              { name: project.name.downcase, platform: project.platform }
            ]
          }
        )
        expect(response).to have_http_status(403)
      end
    end
  end
end
