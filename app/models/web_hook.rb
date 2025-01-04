# frozen_string_literal: true

# == Schema Information
#
# Table name: web_hooks
#
#  id                             :integer          not null, primary key
#  all_project_updates            :boolean          default(FALSE), not null
#  interesting_repository_updates :boolean          default(FALSE), not null
#  last_response                  :string
#  last_sent_at                   :datetime
#  shared_secret                  :string
#  url                            :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  repository_id                  :integer
#  user_id                        :integer
#
# Indexes
#
#  index_web_hooks_on_all_project_updates  (all_project_updates)
#  index_web_hooks_on_repository_id        (repository_id)
#
class WebHook < ApplicationRecord
  belongs_to :repository
  belongs_to :user
  validates_presence_of :url
  validates :url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https])

  before_save :clear_timestamps

  scope :receives_all_project_updates, -> { where(all_project_updates: true) }
  scope :receives_interesting_repository_updates, -> { where(interesting_repository_updates: true) }

  def clear_timestamps
    return unless url_changed?

    self.last_sent_at = nil
    self.last_response = nil
  end

  def send_test_payload
    v = Version.first
    send_new_version(v.project, v.project.platform, v)
  end

  def send_new_version(project, platform, version_or_tag, requirements = [])
    send_payload({
                   event: "new_version",
                   repository: repository&.full_name,
                   platform: platform,
                   name: project.name,
                   version: version_or_tag.number,
                   default_branch: repository&.default_branch,
                   package_manager_url: project.package_manager_url(version_or_tag.number),
                   published_at: version_or_tag.published_at,
                   requirements: requirements,
                   project: project.as_json(only: %i[name platform description homepage language repository_url stars latest_release_published_at normalized_licenses]),
                 },
                 # Right now the sidekiq job that calls send_new_version calls it for
                 # multiple hooks in one job, so raising an error would include multiple
                 # hooks in the same retry. For all new hooks we add, we should not have
                 # this behavior.
                 ignore_errors: true)
  end

  def send_project_updated(project, ignore_errors: false)
    serialized = ProjectUpdatedSerializer.new(project).as_json
    send_payload({
                   event: "project_updated",
                   project: serialized,
                 },
                 ignore_errors: ignore_errors,
                 extra_log_attrs: {
                   project_platform: project.platform,
                   project_name: project.name,
                   project_id: project.id,
                 })
  end

  def send_repository_updated(repository, ignore_errors: false)
    serialized = RepositoryUpdatedSerializer.new(repository).as_json
    send_payload({
                   event: "repository_updated",
                   repository: serialized,
                 },
                 ignore_errors: ignore_errors)
  end

  def request(data)
    body = JSON.dump(data)

    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha512"),
                                        # if there's no secret we send a (pointless) signature anyway
                                        shared_secret || "",
                                        body)

    Typhoeus::Request.new(url,
                          method: :post,
                          timeout_ms: 10000,
                          body: body,
                          headers: {
                            "Content-Type" => "application/json",
                            "Accept-Encoding" => "application/json",
                            "X-Libraries-Signature" => signature,
                          })
  end

  def send_payload(data, ignore_errors: false, extra_log_attrs: {})
    start_time = Time.current
    response = request(data).run
    StructuredLog.capture("WEB_HOOK_SENT",
                          {
                            webhook_id: id,
                            response_timed_out: response.timed_out?,
                            response_code: response.code,
                            response_success: response.success?,
                            # this would be in datadog already if we have a trace, but it seems we
                            # don't always have a trace.
                            request_duration: Time.current - start_time,
                            webhook_event: data[:event],
                          }.merge(extra_log_attrs))
    # for user facing webhooks, we update last sent/last response
    # but skip that for the all_project_updates to avoid hammering
    # the db too much
    update(last_sent_at: Time.now.utc, last_response: response.response_code) unless all_project_updates || interesting_repository_updates
    raise StandardError, "webhook failed webhook_id=#{id} timed_out=#{response.timed_out?} code=#{response.code}" unless response.success? || ignore_errors
  end
end
