# frozen_string_literal: true

module BitbucketProject
  def bitbucket_name_with_owner
    BitbucketURLParser.parse(repository_url) || BitbucketURLParser.parse(homepage)
  end
end
