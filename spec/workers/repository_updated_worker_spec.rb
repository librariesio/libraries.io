# frozen_string_literal: true

require "rails_helper"

describe RepositoryUpdatedWorker do
  context "with a sample webhook" do
    let(:url) { "https://example.com/hook" }
    let(:repository) { create(:repository, interesting: true) }
    let!(:web_hook) { create(:web_hook, repository: nil, url: url, interesting_repository_updates: true) }

    it "should be queued and send the webhook on repository update" do
      WebMock.stub_request(:post, url)
        .to_return(status: 200)

      expect(web_hook.last_sent_at).to be_nil
      expect(WebHook.receives_interesting_repository_updates.to_a).to eq([web_hook])

      repository # create the repo here
      first_updated_at = repository.updated_at

      expect(described_class.jobs.size).to eql 1
      described_class.drain

      assert_requested :post, url,
                       body: be_json_string_matching({
                         event: "repository_updated",
                         repository: {
                           full_name: repository.full_name,
                           host_type: repository.host_type,
                           name: repository.name,
                           updated_at: ActiveModel::Type::DateTime.new(precision: 0).serialize(first_updated_at),
                           url: repository.url,
                         }.stringify_keys,
                       }.stringify_keys)

      repository.touch(time: first_updated_at + 10.seconds)
      second_updated_at = repository.updated_at
      expect(second_updated_at).not_to eq(first_updated_at)

      expect(described_class.jobs.size).to eql 1
      described_class.drain

      assert_requested :post, url,
                       body: be_json_string_matching({
                         event: "repository_updated",
                         repository: {
                           full_name: repository.full_name,
                           host_type: repository.host_type,
                           name: repository.name,
                           updated_at: ActiveModel::Type::DateTime.new(precision: 0).serialize(second_updated_at),
                           url: repository.url,
                         }.stringify_keys,
                       }.stringify_keys)
    end

    context "with an uninteresting repository" do
      let(:repository) { create(:repository, interesting: false) }
      it "should not send any webhook" do
        expect(WebHook.receives_interesting_repository_updates.to_a).to eq([web_hook])

        repository # create the repo here

        expect(described_class.jobs.size).to eql 0
      end
    end
  end
end
