module RepositoryHost
  class Github < Base
    def avatar_url(size = 60)
      "https://avatars.githubusercontent.com/u/#{repository.owner_id}?size=#{size}"
    end

    def download_forks(token = nil)
      return true if repository.fork?
      return true unless repository.forks_count && repository.forks_count > 0 && repository.forks_count < 100
      return true if repository.forks_count == repository.forked_repositories.count
      AuthToken.new_client(token).forks(repository.full_name).each do |fork|
        Repository.create_from_hash(fork)
      end
    end
  end
end
