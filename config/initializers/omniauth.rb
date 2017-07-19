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
  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'], scope: "user:email"
  provider :github_public, ENV['GITHUB_PUBLIC_KEY'], ENV['GITHUB_PUBLIC_SECRET'], scope: "user:email,write:repo_hook,read:org", request_path: '/auth/github_public', callback_path: '/auth/github_public/callback'
  provider :github_private, ENV['GITHUB_PRIVATE_KEY'], ENV['GITHUB_PRIVATE_SECRET'], scope: "user:email,repo,read:org", request_path: '/auth/github_private', callback_path: '/auth/github_private/callback'
  provider :gitlab, ENV['GITLAB_APPLICATION_ID'], ENV['GITLAB_SECRET'], scope: "read_user"
  provider :bitbucket, ENV['BITBUCKET_APPLICATION_ID'], ENV['BITBUCKET_SECRET']
  provider :sourceforge, ENV['SOURCEFORGE_KEY'], ENV['SOURCEFORGE_SECRET']
end

Rails.application.config.default_provider = :github
