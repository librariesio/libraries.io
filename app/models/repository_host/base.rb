module RepositoryHost
  class Base
    def initialize(repository)
      @repository = repository
    end

    def avatar_url(size = 60)
      raise NotImplementedError
    end

    def download_fork_source(token = nil)
      return true unless repository.fork? && repository.source.nil?
    end

    private

    attr_reader :repository
  end
end
