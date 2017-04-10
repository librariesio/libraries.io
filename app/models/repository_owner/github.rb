module RepositoryOwner
  class Github < Base
    def avatar_url(size = 60)
      "https://avatars.githubusercontent.com/u/#{owner.uuid}?size=#{size}"
    end

    def repository_url
      "https://github.com/#{owner.login}"
    end
  end
end
