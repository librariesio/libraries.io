class BitbucketURLParser < URLParser
  private

  def extractable_early?
    return false if bitbucket_website_url?

    match = url.match(/([\w\.@\:\-_~]+)\.bitbucket\.(com|org)\/([\w\.@\:\-\_\~]+)/i)
    if match && match.length == 4
      return "#{match[1]}/#{match[3]}"
    end

    nil
  end

  def parseable?
    !url.nil? && url.include?('bitbucket')
  end

  def remove_domain
    url.gsub!(/(bitbucket.com|bitbucket.org)+?(:|\/)?/i, '')
  end

  def bitbucket_website_url?
    url.match(/www.bitbucket.(com|org)/i)
  end

  def includes_domain?
    url.match(/bitbucket\.(com|org)/i)
  end
end
