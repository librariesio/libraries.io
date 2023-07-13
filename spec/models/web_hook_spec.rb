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
          .to_return { |request| saved_body = request.body; { status: 200 } }

        web_hook.send_new_version(version.project, version.project.platform, version, [])

        expect(saved_body).not_to be_nil

        assert_requested :post, url,
                         headers: { 'X-Libraries-Signature' => compute_signature(saved_body, "") },
                         body: be_json_string_matching(hash_including({
                                                                        event: "new_version",
                                                                        name: project.name,
                                                                        platform: project.platform,
                                                                        # is it silly to duplicate fields at toplevel and in
                                                                        # this nested project hash? yes it is
                                                                        project: hash_including({
                                                                                                  name: project.name,
                                                                                                  platform: project.platform,
                                                                                                }.stringify_keys)
                                                                      }.stringify_keys))
      end

      context "with non-nil secret" do
        let(:shared_secret) { "abcdefg" }

        it "sends the new_version event with a signature using the secret" do
          saved_body = nil
          WebMock.stub_request(:post, url)
            .to_return { |request| saved_body = request.body; { status: 200 } }

          web_hook.send_new_version(version.project, version.project.platform, version, [])

          expect(saved_body).not_to be_nil

          expected_signature = compute_signature(saved_body, shared_secret)
          expect(expected_signature).not_to eq(compute_signature(saved_body, ""))

          assert_requested :post, url,
                           headers: { 'X-Libraries-Signature' => expected_signature }
        end
      end
    end
  end
end
