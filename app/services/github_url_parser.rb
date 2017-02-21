class GithubURLParser < URLParser
  private

  def extractable_early?
    return false if github_website_url?

    match = url.match(/([\w\.@\:\-_~]+)\.github\.(io|com|org)\/([\w\.@\:\-\_\~]+)/i)
    if match && match.length == 4
      return "#{match[1]}/#{match[3]}"
    end

    nil
  end

  def parseable?
    !url.nil? && url.include?('github')
  end

  def remove_domain
    url.gsub!(/(github.io|github.com|github.org|raw.githubusercontent.com)+?(:|\/)?/i, '')
  end

  def github_website_url?
    url.match(/www.github.(io|com|org)/i)
  end

  def includes_domain?
    url.match(/github\.(io|com|org)/i)
  end
end
