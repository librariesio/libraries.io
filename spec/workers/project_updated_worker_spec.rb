# frozen_string_literal: true

require "rails_helper"

describe ProjectUpdatedWorker do
  context "with a sample webhook" do
    let(:url) { "https://example.com/hook" }
    let(:repository) { create(:repository) }
    let!(:web_hook) { create(:web_hook, url: url, repository: repository, all_project_updates: true) }
    let(:project) { create(:project, repository: repository) }
    let(:version) { create(:version, project: project) }

    it "should be queued and send the webhook on project update" do
      WebMock.stub_request(:post, url)
        .to_return(status: 200)

      expect(web_hook.last_sent_at).to be_nil
      expect(WebHook.receives_all_project_updates.to_a).to eq([web_hook])

      project # create the project here
      first_updated_at = project.updated_at

      described_class.drain

      expected_payload = {
        created_at: ActiveModel::Type::DateTime.new(precision: 0).serialize(project.created_at),
        dependents_count: project.dependents_count,
        homepage: project.homepage,
        keywords_array: project.keywords_array,
        latest_release_number: project.latest_release_number,
        latest_release_published_at: ActiveModel::Type::DateTime.new(precision: 0).serialize(project.latest_release_published_at),
        latest_stable_release_number: project.latest_stable_release_number,
        name: project.name,
        platform: project.platform,
        repository_url: project.repository_url,
        status: project.status,
        updated_at: ActiveModel::Type::DateTime.new(precision: 0).serialize(first_updated_at),
        versions_count: project.versions_count,
      }.stringify_keys

      assert_requested :post, url,
                       body: be_json_string_matching({
                         event: "project_updated",
                         project: expected_payload,
                       }.stringify_keys)

      project.touch(time: first_updated_at + 10.seconds)
      second_updated_at = project.updated_at
      expect(second_updated_at).not_to eq(first_updated_at)

      described_class.drain

      second_expected_payload =
        expected_payload
          .merge({
                   "updated_at" => ActiveModel::Type::DateTime.new(precision: 0).serialize(second_updated_at),
                   # we use updated_at for latest_release_published_at if latest_release_published_at is null
                   "latest_release_published_at" => ActiveModel::Type::DateTime.new(precision: 0).serialize(project.latest_release_published_at),
                 })

      assert_requested :post, url,
                       body: be_json_string_matching({
                         event: "project_updated",
                         project: second_expected_payload,
                       }.stringify_keys)
    end

    it "should raise an error on non-200" do
      WebMock.stub_request(:post, url)
        .to_return(status: 500)

      project # create the project here
      expect do
        described_class.new.perform(project.id, web_hook.id)
      end.to raise_error(/webhook failed.*code=500/)
    end
  end
end
