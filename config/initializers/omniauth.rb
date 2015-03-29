class GithubAuthOptions
  def initialize(env)
    @request = Rack::Request.new(env)
  end

  def to_hash
    if 'private' == @request.params['role']
      {scope: 'repo,user:email'}
    else
      {}
    end
  end
end

module OmniAuth
  module Strategies
    class Developer2 < Developer
      credentials do
        { 'token' => request.params[options.uid_field.to_s] }
      end
    end
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer2, fields: [:nickname], uid_field: :nickname unless Rails.env.production?

  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'], setup: ->(env) {
    options = GithubAuthOptions.new(env)
    env['omniauth.strategy'].options.merge!(options.to_hash)
  }
end

Rails.application.config.default_provider = (Rails.env.development? && ENV['GITHUB_KEY'].blank?) ? :developer2 : :github
