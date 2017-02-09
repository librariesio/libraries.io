module GithubProject
  def github_url
    return nil if repository_url.blank? || github_name_with_owner.blank?
    "https://github.com/#{github_name_with_owner}"
  end

  def github_name_with_owner
    GithubUrls.parse(repository_url) || GithubUrls.parse(homepage)
  end
end
