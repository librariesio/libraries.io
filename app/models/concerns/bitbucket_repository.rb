module BitbucketRepository
  extend ActiveSupport::Concern

  included do
    IGNORABLE_BITBUCKET_EXCEPTIONS = [BitBucket::Error::NotFound, BitBucket::Error::Forbidden]

    def self.bitbucket_client(token = nil)
      BitBucket.new oauth_token: token || ENV['BITBUCKET_KEY']
    end

    def self.recursive_bitbucket_repos(url, limit = 10)
      return if limit.zero?
      r = Typhoeus::Request.new(url,
        method: :get,
        headers: { 'Accept' => 'application/json' }).run

      json = Oj.load(r.body)

      json['values'].each do |repo|
        CreateRepositoryWorker.perform_async('Bitbucket', repo['full_name'])
      end
      puts json['next']
      if json['values'].any? && json['next']
        limit = limit - 1
        REDIS.set 'bitbucket-after', Addressable::URI.parse(json['next']).query_values['after']
        recursive_bitbucket_repos(json['next'], limit)
      end
    end
  end

  def download_bitbucket_owner
    # not implemented yet
  end

  def download_bitbucket_contributions
    # not implemented yet
  end

  def bitbucket_create_webhook
    # not implemented yet
  end

  def download_bitbucket_issues
    # not implemented yet
  end

  def bitbucket_client(token = nil)
    Repository.bitbucket_client(token)
  end
  
  def get_bitbucket_file_list(token = nil)
    bitbucket_client(token).get_request("1.0/repositories/#{full_name}/directory/")[:values]
  end

  def get_bitbucket_file_contents(path, token = nil)
    user_name, repo_name = full_name.split('/')
    bitbucket_client(token).repos.sources.list(user_name, repo_name, 'master', path).data
  end
end
