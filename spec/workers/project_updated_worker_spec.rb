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

      assert_requested :post, url,
                       body: be_json_string_matching({
                         event: "project_updated",
                         project: {
                           name: project.name,
                           platform: project.platform,
                           updated_at: ActiveModel::Type::DateTime.new(precision: 0).serialize(first_updated_at),
                         }.stringify_keys,
                       }.stringify_keys)

      project.touch(time: first_updated_at + 10.seconds)
      second_updated_at = project.updated_at
      expect(second_updated_at).not_to eq(first_updated_at)

      described_class.drain

      assert_requested :post, url,
                       body: be_json_string_matching({
                         event: "project_updated",
                         project: {
                           name: project.name,
                           platform: project.platform,
                           updated_at: ActiveModel::Type::DateTime.new(precision: 0).serialize(second_updated_at),
                         }.stringify_keys,
                       }.stringify_keys)
    end
  end
end
