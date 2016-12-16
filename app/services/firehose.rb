class Firehose
  class << self
    def new_version(project, platform, version_or_tag)
      return unless Rails.env.production?
      Typhoeus::Request.new('http://firehose.libraries.io/events',
        method: :post,
        params: {
          api_key: ENV['FIREHOSE_KEY']
        },
        body: Oj.dump({
          platform: platform,
          name: project.name,
          version: version_or_tag.number,
          package_manager_url: project.package_manager_url(version_or_tag.number),
          published_at: version_or_tag.published_at.to_s,
          project: project.as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords])
        }, mode: :compat),
        headers: { 'Content-Type' => 'application/json' }).run
    end
  end
end
