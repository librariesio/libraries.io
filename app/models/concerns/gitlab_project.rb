# frozen_string_literal: true
module GitlabProject
  def gitlab_name_with_owner
    GitlabURLParser.parse(repository_url) || GitlabURLParser.parse(homepage)
  end
end
