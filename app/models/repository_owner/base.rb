# frozen_string_literal: true

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

    def top_favourite_projects
      Project.visible.where(id: top_favourite_project_ids).maintained.order(Arel.sql("position(','||projects.id::text||',' in '#{top_favourite_project_ids.join(',')}')"))
    end

    def top_contributors
      RepositoryUser.where(id: top_contributor_ids).order(Arel.sql("position(','||repository_users.id::text||',' in '#{top_contributor_ids.join(',')}')"))
    end

    def to_s
      owner.name.presence || owner.login
    end

    def to_param
      {
        host_type: owner.host_type.downcase,
        login: owner.login,
      }
    end

    def github_id
      owner.uuid
    end

    def download_orgs
      raise NotImplementedError
    end

    def download_repos
      raise NotImplementedError
    end

    def api_client(_token = nil)
      self.class.api_client
    end

    def self.format(host_type)
      case host_type.try(:downcase) # rubocop: disable Style/HashLikeCase
      when "github"
        "GitHub"
      when "gitlab"
        "GitLab"
      when "bitbucket"
        "Bitbucket"
      end
    end

    def check_status
      response = Typhoeus.head(repository_url)

      if response.response_code == 404
        owner.repositories.each do |repo|
          CheckRepoStatusWorker.perform_async(repo.host_type, repo.full_name)
        end
        owner.destroy
      end
    end

    def formatted_host
      self.class.format(owner.host_type)
    end

    def download_user_from_host
      download_user_from_host_by(owner.uuid)
    rescue StandardError
      download_user_from_host_by_login
    end

    def download_user_from_host_by_login
      download_user_from_host_by(owner.login)
    end

    def download_user_from_host_by(id_or_login)
      self.class.download_user_from_host(owner.host_type, id_or_login)
    end

    def self.download_user_from_host(host_type, id_or_login)
      RepositoryUser.create_from_host(host_type, fetch_user(id_or_login))
    end

    def download_org_from_host
      download_org_from_host_by(owner.uuid)
    rescue StandardError
      download_org_from_host_by_login
    end

    def download_org_from_host_by_login
      download_org_from_host_by(owner.login)
    end

    def download_org_from_host_by(id_or_login)
      self.class.download_org_from_host(owner.host_type, id_or_login)
    end

    def self.download_org_from_host(host_type, id_or_login)
      RepositoryOrganisation.create_from_host(host_type, fetch_org(id_or_login))
    end

    def self.fetch_user(id_or_login)
      raise NotImplementedError
    end

    def self.fetch_org(id_or_login)
      raise NotImplementedError
    end

    private

    def top_favourite_project_ids
      Rails.cache.fetch [owner, "top_favourite_project_ids"], expires_in: 1.week, race_condition_ttl: 2.minutes do
        owner.favourite_projects.limit(10).pluck(:id)
      end
    end

    def top_contributor_ids
      Rails.cache.fetch [owner, "top_contributor_ids"], expires_in: 1.week, race_condition_ttl: 2.minutes do
        owner.contributors.visible.limit(50).pluck(:id)
      end
    end
  end
end
