module BitbucketRepository
  extend ActiveSupport::Concern

  included do
    IGNORABLE_BITBUCKET_EXCEPTIONS = [BitBucket::Error::NotFound, BitBucket::Error::Forbidden]

    def self.create_from_bitbucket(full_name, token = nil)
      repo_hash = map_from_bitbucket(full_name, token)
      create_from_hash(repo_hash)
    rescue *IGNORABLE_BITBUCKET_EXCEPTIONS
      nil
    end

    def self.bitbucket_client(token = nil)
      BitBucket.new oauth_token: token || ENV['BITBUCKET_KEY']
    end

    def self.map_from_bitbucket(full_name, token = nil)
      client = bitbucket_client(token)
      user_name, repo_name = full_name.split('/')
      project = client.repos.get(user_name, repo_name)
      v1_project = client.repos.get(user_name, repo_name, api_version: '1.0')
      repo_hash = project.to_hash.with_indifferent_access.slice(:description, :language, :full_name, :name, :has_wiki, :has_issues, :scm)

      repo_hash.merge!({
        id: project.uuid,
        host_type: 'Bitbucket',
        owner: {},
        homepage: project.website,
        fork: project.parent.present?,
        created_at: project.created_on,
        updated_at: project.updated_on,
        subscribers_count: v1_project.followers_count,
        forks_count: v1_project.forks_count,
        private: project.is_private,
        size: project[:size].to_f/1000,
        parent: {
          full_name: project.fetch('parent', {}).fetch('full_name', nil)
        }
      })
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

  def bitbucket_client(token = nil)
    Repository.bitbucket_client(token)
  end
end
