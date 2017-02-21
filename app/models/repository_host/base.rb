module RepositoryHost
  class Base
    def initialize(repository)
      @repository = repository
    end

    def avatar_url(size = 60)
      raise NotImplementedError
    end

    private

    attr_reader :repository
  end
end
