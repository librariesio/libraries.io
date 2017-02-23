module RepositoryHost
  class Base
    def initialize(repository)
      @repository = repository
    end

    def self.create(full_name, token = nil)
      Repository.create_from_hash(fetch_repo(full_name, token))
    rescue *IGNORABLE_EXCEPTIONS
      nil
    end

    def avatar_url(size = 60)
      raise NotImplementedError
    end

    def download_fork_source(token = nil)
      self.class.fetch_repo(repository.source_name, token) if download_fork_source?
    end

    def download_fork_source?
      repository.fork? && repository.source_name.present? && repository.source.nil?
    end

    def self.format(host_type)
      case host_type.try(:downcase)
      when 'github'
        'GitHub'
      when 'gitlab'
        'GitLab'
      when 'bitbucket'
        'Bitbucket'
      end
    end

    def formatted_host
      self.class.format(repository.host_type)
    end

    private

    attr_reader :repository
  end
end
