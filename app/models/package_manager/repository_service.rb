# frozen_string_literal: true

module PackageManager
  class RepositoryService
    # Use librariesio-url-parser to attempt to select one of the provided
    # URLs as the URL for this repository. This means that if the URL is
    # not considered a repository URL by that gem, its raw value will be
    # used. This would allow for a project that self-hosts to still have
    # a valid repo URL.
    #
    # @param repo String A string we think is a project's repository URL
    # @param homepage String A string we thing is a project's homepage URL
    # @return String The best URL we can select for the project's repository, or "" if we can't find one
    def self.repo_fallback(repo, homepage)
      repo = "" if repo.nil?
      homepage = "" if homepage.nil?
      repo_url = URLParser.try_all(repo)
      homepage_url = URLParser.try_all(homepage)
      repo_url.presence || homepage_url.presence || repo
    end
  end
end
