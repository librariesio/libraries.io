module BitbucketRepository
  extend ActiveSupport::Concern

  included do
    IGNORABLE_BITBUCKET_EXCEPTIONS = []

    def self.create_from_bitbucket(full_name, token = nil)
      client = bitbucket_client(token)
      user_name, repo_name = full_name.split('/')
      project = client.repos.get(user_name, repo_name)

      repo_hash = project.to_hash.with_indifferent_access.slice(:description, :language, :full_name, :name, :forks_count, :has_wiki, :has_issues, :scm, :size)

      repo_hash.merge!({
        id: project.uuid,
        host_type: 'Bitbucket',
        owner: {},
        homepage: project.website,
        fork: project.fork_of,
        created_at: project.utc_created_on,
        updated_at: project.utc_last_updated,
        stargazers_count: project.followers_count,
        private: project.is_private
      })
      create_from_hash(repo_hash)
    rescue *IGNORABLE_BITBUCKET_EXCEPTIONS
      nil
    end

    def self.bitbucket_client(token = nil)
      BitBucket.new oauth_token: token || ENV['BITBUCKET_KEY']
    end
  end

  def bitbucket_client(token = nil)
    Repository.bitbucket_client(token)
  end

  def bitbucket_avatar_url(size = 60)
    "https://bitbucket.org/#{full_name}/avatar/#{size}"
  end
end
