module RepoUrls
  extend ActiveSupport::Concern

  included do
    def self.host_domain(host_type)
      case host_type
      when 'GitHub'
        'https://github.com'
      when 'GitLab'
        'https://gitlab.com'
      when 'Bitbucket'
        'https://bitbucket.org'
      end
    end
  end

  def host_url
    Repository.host_domain(host_type)
  end

  def url
    "#{host_url}/#{full_name}"
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
    case host_type
    when 'GitHub'
      author_param = author.present? ? "?author=#{author}" : ''
      "#{url}/commits#{author_param}"
    when 'GitLab'
      "#{url}/commits/#{default_branch}"
    when 'Bitbucket'
      "#{url}/commits"
    end
  end
end
