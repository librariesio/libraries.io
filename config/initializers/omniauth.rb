module OmniAuth
  module Strategies
    class GithubPublic < GitHub
    end
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'], scope: "user:email"
  provider :github_public, ENV['GITHUB_PUBLIC_KEY'], ENV['GITHUB_PUBLIC_SECRET'], scope: "user:email,public_repo", request_path: '/auth/github_public', callback_path: '/auth/github_public/callback'
end

Rails.application.config.default_provider = :github
