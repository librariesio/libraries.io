module RepositoryHost
  class Github < Base
    def avatar_url(size = 60)
      "https://avatars.githubusercontent.com/u/#{repository.owner_id}?size=#{size}"
    end
  end
end
