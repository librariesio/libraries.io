# frozen_string_literal: true
module RepositoryHost
  class Base
    def initialize(repository)
      @repository = repository
    end

    def self.create(full_name, token = nil)
      Repository.create_from_hash(fetch_repo(full_name, token))
    rescue *self::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.domain(host_type)
      RepositoryHost.const_get(host_type.capitalize).new(nil).domain
    end

    def url
      "#{domain}/#{repository.full_name}"
    end

    def issues_url
      "#{url}/issues"
    end

    def source_url
      "#{domain}/#{repository.source_name}"
    end

    def raw_url(sha = nil)
      sha ||= repository.default_branch
      "#{url}/raw/#{sha}/"
    end

    def compare_url(branch_one, branch_two)
      "#{url}/compare/#{branch_one}...#{branch_two}"
    end

    def watchers_url
      nil
    end

    def forks_url
      nil
    end

    def stargazers_url
      nil
    end

    def contributors_url
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

    def repository_owner_class
      RepositoryOwner.const_get(repository.host_type.capitalize)
    end

    def update_from_host(token = nil)
      begin
        r = self.class.fetch_repo(repository.id_or_name)
        return unless r.present?
        repository.uuid = r[:id] unless repository.uuid.to_s == r[:id].to_s
        if repository.full_name.downcase != r[:full_name].downcase
          clash = Repository.host(r[:host_type]).where('lower(full_name) = ?', r[:full_name].downcase).first
          if clash && (!clash.repository_host.update_from_host(token) || clash.status == "Removed")
            clash.destroy
          end
          repository.full_name = r[:full_name]
        end
        repository.license = Project.format_license(r[:license][:key]) if r[:license]
        if r[:fork]
          repository.source_name = r[:parent][:full_name]
        else
          repository.source_name = nil
        end
        repository.assign_attributes r.slice(*Repository::API_FIELDS)
        repository.save! if repository.changed?
      rescue self.class.api_missing_error_class
        repository.update_attribute(:status, 'Removed') if !repository.private?
      rescue *self.class::IGNORABLE_EXCEPTIONS
        nil
      end
    end

    def gather_maintenance_stats_async
      RepositoryMaintenanceStatWorker.enqueue(repository.id, priority: :medium)
    end

    def gather_maintenance_stats
      # should be overwritten in individual repository_host class
      []
    end

    private

    attr_reader :repository

    def add_metrics_to_repo(results)
      # create one hash with all results
      results.reduce(Hash.new, :merge).each do |category, value|
          unless value.nil?
              stat = repository.repository_maintenance_stats.find_or_create_by(category: category.to_s)
              stat.update!(value: value.to_s)
              stat.touch unless stat.changed?  # we always want to update updated_at for later querying
          end
      end
    end
  end
end
