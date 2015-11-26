class Firehose
  class << self
    def new_version(project, platform, version_or_tag)
      return unless Rails.env.production?
      Typhoeus::Request.new('http://libfirehose.herokuapp.com/events',
        method: :post,
        body: Oj.dump({
          platform: platform,
          name: project.name,
          version: version_or_tag.number,
          package_manager_url: Repositories::Base.package_link(project, version_or_tag),
          published_at: version_or_tag.published_at,
          project: project.as_json(only: [:name, :platform, :description,  :homepage, :language, :repository_url, :stars, :latest_release_published_at, :normalized_licenses])
        }, mode: :compat),
        headers: { 'Content-Type' => 'application/json' }).run
    end
  end
end
