module BitbucketProject
  def bitbucket_name_with_owner
    BitbucketUrls::Parser.parse(repository_url) || BitbucketUrls::Parser.parse(homepage)
  end
end
