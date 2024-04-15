# frozen_string_literal: true

require "rails_helper"

describe WebHook, type: :model do
  it { should belong_to(:repository) }
  it { should belong_to(:user) }
  it { should validate_presence_of(:url) }

  context "with a sample webhook" do
    let(:url) { "https://example.com/hook" }
    let(:project) { create(:project) }
    let(:version) { create(:version, project: project) }
    let(:shared_secret) { nil }
    let(:web_hook) { create(:web_hook, url: url, repository: project.repository, shared_secret: shared_secret) }

    def compute_signature(body, shared_secret)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha512"),
                              shared_secret,
                              body)
    end

    describe "#send_new_version" do
      it "sends the new_version event" do
        saved_body = nil
        WebMock.stub_request(:post, url)
          .to_return do |request|
            saved_body = request.body
            { status: 200 }
          end

        web_hook.send_new_version(version.project, version.project.platform, version, [])

        expect(saved_body).not_to be_nil

        assert_requested :post, url,
                         headers: { "X-Libraries-Signature" => compute_signature(saved_body, "") },
                         body: be_json_string_matching(hash_including({
                           event: "new_version",
                           name: project.name,
                           platform: project.platform,
                           # is it silly to duplicate fields at toplevel and in
                           # this nested project hash? yes it is
                           project: hash_including({
                             name: project.name,
                             platform: project.platform,
                           }.stringify_keys),
                         }.stringify_keys))
      end

      it "does not raise an error if the receiver returns 500" do
        WebMock.stub_request(:post, url)
          .to_return(status: 500)

        expect do
          web_hook.send_new_version(version.project, version.project.platform, version, [])
        end.not_to raise_error
      end

      it "does not raise an error if the receiver times out" do
        WebMock.stub_request(:post, url)
          .to_timeout

        expect do
          web_hook.send_new_version(version.project, version.project.platform, version, [])
        end.not_to raise_error
      end

      context "with non-nil secret" do
        let(:shared_secret) { "abcdefg" }

        it "sends the new_version event with a signature using the secret" do
          saved_body = nil
          WebMock.stub_request(:post, url)
            .to_return do |request|
              saved_body = request.body
              { status: 200 }
            end

          web_hook.send_new_version(version.project, version.project.platform, version, [])

          expect(saved_body).not_to be_nil

          expected_signature = compute_signature(saved_body, shared_secret)
          expect(expected_signature).not_to eq(compute_signature(saved_body, ""))

          assert_requested :post, url,
                           headers: { "X-Libraries-Signature" => expected_signature }
        end
      end
    end

    describe "#send_project_updated" do
      it "sends the project_updated event" do
        WebMock.stub_request(:post, url)
          .to_return(status: 200)
        web_hook.send_project_updated(project)

        assert_requested :post, url,
                         body: be_json_string_matching({
                           event: "project_updated",
                           project: {
                             name: project.name,
                             platform: project.platform,
                             # this seems a little awkward but not sure what else to do to match
                             # exactly how the serializer serializes this timestamp
                             updated_at: ActiveModel::Type::DateTime.new(precision: 0).serialize(project.updated_at),
                           }.stringify_keys,
                         }.stringify_keys)
      end

      it "raises an error if the receiver returns 500" do
        WebMock.stub_request(:post, url)
          .to_return(status: 500)

        expect do
          web_hook.send_project_updated(project)
        end.to raise_error(/webhook failed webhook_id=#{web_hook.id} timed_out=false code=500/)
      end

      it "raises an error if the receiver times out" do
        WebMock.stub_request(:post, url)
          .to_timeout

        expect do
          web_hook.send_project_updated(project)
        end.to raise_error(/webhook failed webhook_id=#{web_hook.id} timed_out=true code=0/)
      end
    end
  end
end
