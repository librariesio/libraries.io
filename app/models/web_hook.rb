class WebHook < ActiveRecord::Base
  belongs_to :github_repository
  belongs_to :user
  validates_presence_of :url
  validates :url, :format => URI::regexp(%w(http https))

  def send_test_payload
    v = Version.first
    send_new_version(v.project, v.project.platform, v)
  end

  def send_new_version(project, platform, version_or_tag)
    send_payload({
      platform: platform,
      name: project.name,
      version: version_or_tag.number,
      package_manager_url: Repositories::Base.package_link(project, version_or_tag),
      published_at: version_or_tag.published_at,
      project: project.as_json(only: [:name, :platform, :description,  :homepage, :language, :repository_url, :stars, :latest_release_published_at, :normalized_licenses])
    })
  end

  def request(data)
    Typhoeus::Request.new(url,
      method: :post,
      timeout_ms: 10000,
      body: Oj.dump(data, mode: :compat),
      headers: { 'Content-Type' => 'application/json', 'Accept-Encoding' => 'application/json' })
  end

  def send_payload(data)
    response = request(data).run
    update_attributes(last_sent_at: Time.now.utc, last_response: response.response_code)
  end
end
