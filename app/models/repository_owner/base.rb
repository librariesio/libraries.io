module RepositoryOwner
  class Base
    attr_reader :owner

    def initialize(owner)
      @owner = owner
    end

    def avatar_url(size = 60)
      raise NotImplementedError
    end

    def repository_url
      raise NotImplementedError
    end
  end
end
