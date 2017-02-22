class BitbucketURLParser < URLParser
  private

  def tlds
    %w(com org)
  end

  def domain
    'bitbucket'
  end

  def remove_domain
    url.gsub!(/(bitbucket.com|bitbucket.org)+?(:|\/)?/i, '')
  end
end
