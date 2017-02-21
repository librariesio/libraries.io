class GitlabURLParser < URLParser
  private

  def extractable_early?
    return false if gitlab_website_url?

    match = url.match(/([\w\.@\:\-_~]+)\.gitlab\.com\/([\w\.@\:\-\_\~]+)/i)
    if match && match.length == 4
      return "#{match[1]}/#{match[3]}"
    end

    nil
  end

  def parseable?
    !url.nil? && url.include?('gitlab')
  end

  def remove_domain
    url.gsub!(/(gitlab.com)+?(:|\/)?/i, '')
  end

  def gitlab_website_url?
    url.match(/www.gitlab.com/i)
  end

  def includes_domain?
    url.match(/gitlab\.com/i)
  end
end
