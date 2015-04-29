class GitterNotifications
  class << self
    def new_project(project_name, platform)
      post_to_gitter "[#{platform}] **[#{project_name}](https://libraries.io/#{platform}/#{project_name})** has been added"
    end

    def new_version(project_name, platform, version)
      post_to_gitter("[#{platform}] **[#{project_name}](https://libraries.io/#{platform}/#{project_name}/#{version})** #{version} has been added")
    end

    def post_to_gitter(message)
      return unless Rails.env.production?
      Typhoeus::Request.new("https://webhooks.gitter.im/e/5c404ff65201c8e9bed8", method: :post, body: { 'message' => message }).run
    end
  end
end
