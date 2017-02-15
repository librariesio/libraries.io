module GitlabProject
  def gitlab_name_with_owner
    GitlabUrls::Parser.parse(repository_url) || GitlabUrls::Parser.parse(homepage)
  end
end
