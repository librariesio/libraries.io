# frozen_string_literal: true

class WebHook < ApplicationRecord
  belongs_to :repository
  belongs_to :user
  validates_presence_of :url
  validates :url, format: URI.regexp(%w[http https])

  before_save :clear_timestamps

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
                   repository: repository.full_name,
                   platform: platform,
                   name: project.name,
                   version: version_or_tag.number,
                   default_branch: repository.default_branch,
                   package_manager_url: project.package_manager_url(version_or_tag.number),
                   published_at: version_or_tag.published_at,
                   requirements: requirements,
                   project: project.as_json(only: %i[name platform description homepage language repository_url stars latest_release_published_at normalized_licenses]),
                 })
  end

  def request(data)
    Typhoeus::Request.new(url,
                          method: :post,
                          timeout_ms: 10000,
                          body: JSON.dump(data),
                          headers: { "Content-Type" => "application/json", "Accept-Encoding" => "application/json" })
  end

  def send_payload(data)
    response = request(data).run
    update_attributes(last_sent_at: Time.now.utc, last_response: response.response_code)
  end
end
