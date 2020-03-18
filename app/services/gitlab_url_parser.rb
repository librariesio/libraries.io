# frozen_string_literal: true

class GitlabURLParser < URLParser
  private

  def full_domain
    "https://gitlab.com"
  end

  def tlds
    %w[com]
  end

  def domain
    "gitlab"
  end

  def remove_domain
    url.gsub!(/(gitlab.com)+?(:|\/)?/i, "")
  end
end
