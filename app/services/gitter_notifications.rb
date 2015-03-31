class GitterNotifications
  class << self
    def new_project(project_name, platform)
      return unless Rails.env.production?
      uri = URI.parse("https://webhooks.gitter.im/e/5c404ff65201c8e9bed8")
      message = "[#{platform}] **[#{project_name}](http://libraries.io/#{platform}/#{project_name})** has been added"
      Net::HTTP.post_form(uri, {"message" => message})
    end

    def new_version(project_name, platform, version)
      return unless Rails.env.production?
      uri = URI.parse("https://webhooks.gitter.im/e/5c404ff65201c8e9bed8")
      message = "[#{platform}] **[#{project_name}](http://libraries.io/#{platform}/#{project_name}/#{version})** #{version} has been added"
      Net::HTTP.post_form(uri, {"message" => message})
    end
  end
end
