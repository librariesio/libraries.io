module RepositoryHost
  class Bitbucket < Base
    def avatar_url(size = 60)
      "https://bitbucket.org/#{repository.full_name}/avatar/#{size}"
    end
  end
end
