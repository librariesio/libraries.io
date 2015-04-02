class Firehose
  class << self
    def new_version(project_name, platform, version)
      return unless Rails.env.production?
      Typhoeus::Request.new('http://libfirehose.herokuapp.com/events',
        method: :post,
        body: Oj.dump({ platform: platform, name: project_name, version: version }, mode: :compat),
        headers: { 'Content-Type' => 'application/json' }).run
    end
  end
end
