module RepositoryOwner
  class Gitlab < Base
    def avatar_url(size = 60)
      "https://gitlab.com/uploads/user/avatar/#{owner.uuid}/avatar.png"
    end

    def repository_url
      "https://gitlab.com/#{owner.login}"
    end
  end
end
