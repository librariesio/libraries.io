module GithubProject
  def github_name_with_owner
    GithubURLParser.parse(repository_url) || GithubURLParser.parse(homepage)
  end
end
