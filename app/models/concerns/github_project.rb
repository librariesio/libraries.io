module GithubProject
  def github_name_with_owner
    GithubUrls.parse(repository_url) || GithubUrls.parse(homepage)
  end
end
