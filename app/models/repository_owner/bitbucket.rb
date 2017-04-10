module RepositoryOwner
  class Bitbucket < Base
    def avatar_url(size = 60)
      "https://bitbucket.org/account/#{owner.login}/avatar/256/?ts=#{owner.uuid}"
    end

    def repository_url
      "https://bitbucket.org/#{owner.login}"
    end
  end
end
