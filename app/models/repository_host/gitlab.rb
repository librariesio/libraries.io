module RepositoryHost
  class Gitlab < Base
    def avatar_url(_size = 60)
      repository.logo_url
    end
  end
end
