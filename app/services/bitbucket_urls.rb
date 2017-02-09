module BitbucketUrls
  class Parser
    def self.parse(url)
      new(url).parse
    end

    attr_accessor :url

    def initialize(url)
      @url = url
    end

    def parse
      return nil unless parseable?

      if url = extractable_early?
        url
      else
        clean_url
      end
    end

    def clean_url
      remove_whitespace
      remove_brackets
      remove_anchors
      remove_querystring
      remove_auth_user
      remove_equals_sign
      remove_scheme
      return nil unless bitbucket_domain?
      remove_subdomain
      remove_bitbucket_domain
      remove_git_extension
      remove_git_scheme
      remove_extra_segments
      format_url
    end

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

    def remove_extra_segments
      self.url = url.split('/').reject(&:blank?)[0..1]
    end

    def remove_brackets
      url.gsub!(/>|<|\(|\)|\[|\]/, '')
    end

    def remove_querystring
      url.gsub!(/(\?\S*)$/i, '')
    end

    def remove_anchors
      url.gsub!(/(#\S*)$/i, '')
    end

    def remove_git_scheme
      url.gsub!(/git\/\//i, '')
    end

    def remove_git_extension
      url.gsub!(/(\.git|\/)$/i, '')
    end

    def remove_equals_sign
      self.url = url.split('=')[-1]
    end

    def remove_auth_user
      self.url = url.split('@')[-1]
    end

    def remove_whitespace
      url.gsub!(/\s/, '')
    end

    def remove_scheme
      url.gsub!(/(((git\+https|git|ssh|hg|svn|scm|http|https)+?:)+?)/i, '')
    end

    def remove_subdomain
      url.gsub!(/(www|ssh|raw|git|wiki)+?\./i, '')
    end

    def remove_bitbucket_domain
      url.gsub!(/(bitbucket.com|bitbucket.org)+?(:|\/)?/i, '')
    end

    def bitbucket_website_url?
      url.match(/www.bitbucket.(com|org)/i)
    end

    def bitbucket_domain?
      url.match(/bitbucket\.(com|org)/i)
    end

    def format_url
      return nil unless url.length == 2
      url.join('/')
    end
  end
end
