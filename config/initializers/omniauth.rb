# frozen_string_literal: true

module OmniAuth
  module Strategies
    class GithubPublic < GitHub
    end
  end
end

module OmniAuth
  module Strategies
    class GithubPrivate < GitHub
    end
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, Rails.configuration.github_key, Rails.configuration.github_secret, scope: "user:email"
  provider :github_public, Rails.configuration.github_public_key, Rails.configuration.github_public_secret, scope: "user:email,write:repo_hook,read:org", request_path: "/auth/github_public", callback_path: "/auth/github_public/callback"
  provider :github_private, Rails.configuration.github_private_key, Rails.configuration.github_private_secret, scope: "user:email,repo,read:org", request_path: "/auth/github_private", callback_path: "/auth/github_private/callback"
  provider :gitlab, Rails.configuration.gitlab_application_id, Rails.configuration.gitlab_secret, scope: "read_user"
  provider :bitbucket, Rails.configuration.bitbucket_application_id, Rails.configuration.bitbucket_secret
end

Rails.application.config.default_provider = :github
OmniAuth.config.allowed_request_methods = [:get, :post]