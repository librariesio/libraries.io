module RepoUrls
  def pages_url
    case host_type
    when 'GitHub'
      "http://#{owner_name}.github.io/#{project_name}"
    when 'GitLab'
      "http://#{owner_name}.gitlab.io/#{project_name}"
    end
  end

  def wiki_url
    case host_type
    when 'GitHub'
      "#{url}/wiki"
    when 'GitLab'
      "#{url}/wikis"
    when 'Bitbucket'
      "#{url}/wiki"
    end
  end

  def watchers_url
    case host_type
    when 'GitHub'
      "#{url}/watchers"
    end
  end

  def forks_url
    case host_type
    when 'GitHub'
      "#{url}/network"
    when 'GitLab'
      "#{url}/forks"
    end
  end

  def stargazers_url
    case host_type
    when 'GitHub'
      "#{url}/stargazers"
    end
  end

  def issues_url
    "#{url}/issues"
  end

  def contributors_url
    case host_type
    when 'GitHub'
      "#{url}/graphs/contributors"
    when 'GitLab'
      "#{url}/graphs/#{default_branch}"
    end
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
