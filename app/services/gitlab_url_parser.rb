class GitlabURLParser < URLParser
  private

  def tlds
    %w(com)
  end

  def domain
    'gitlab'
  end

  def remove_domain
    url.gsub!(/(gitlab.com)+?(:|\/)?/i, '')
  end
end
