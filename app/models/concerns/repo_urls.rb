module RepoUrls
  def pages_url
    "http://#{owner_name}.github.io/#{project_name}"
  end

  def wiki_url
    "#{url}/wiki"
  end

  def watchers_url
    "#{url}/watchers"
  end

  def forks_url
    "#{url}/network"
  end

  def stargazers_url
    "#{url}/stargazers"
  end

  def issues_url
    "#{url}/issues"
  end

  def contributors_url
    "#{url}/graphs/contributors"
  end

  def host_url
    case host_type
    when 'GitHub'
      'https://github.com'
    when 'GitLab'
      'https://gitlab.com'
    when 'Bitbucket'
      'https://bitbucket.org'
    end
  end

  def url
    "#{host_url}/#{full_name}"
  end

  def source_url
    "#{host_url}/#{source_name}"
  end

  def blob_url
    "#{url}/blob/#{default_branch}/"
  end

  def raw_url
    "#{url}/raw/#{default_branch}/"
  end

  def commits_url(author = nil)
    author_param = author.present? ? "?author=#{author}" : ''
    "#{url}/commits#{author_param}"
  end

  def readme_url
    "#{url}#readme"
  end

  def tags_url
    "#{url}/tags"
  end
end
