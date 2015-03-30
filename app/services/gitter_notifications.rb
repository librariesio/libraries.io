class GitterNotifications
  class << self
    def new_project(project_name, platform)
      uri = URI.parse("https://webhooks.gitter.im/e/5c404ff65201c8e9bed8")
      message = "[#{platform}] **#{project_name}** has been added to libraries."
      Net::HTTP.post_form(uri, {"message" => message})
    end

    def new_version(project_name, platform, version)
      uri = URI.parse("https://webhooks.gitter.im/e/5c404ff65201c8e9bed8")
      message = "[#{platform}] **#{project_name}** #{version} has been added to libraries."
      Net::HTTP.post_form(uri, {"message" => message})
    end
  end
end
