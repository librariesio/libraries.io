module RepositoryOwner
  class Github < Base
    def avatar_url(size = 60)
      "https://avatars.githubusercontent.com/u/#{owner.uuid}?size=#{size}"
    end

    def repository_url
      "https://github.com/#{owner.login}"
    end

    def download_user_from_host
      download_user_from_host_by(owner.uuid.to_i) rescue download_user_from_host_by_login
    end

    def download_org_from_host
      download_org_from_host_by(owner.uuid.to_i) rescue download_org_from_host_by_login
    end

    def download_orgs
      return if owner.org?
      api_client.orgs(owner.login).each do |org|
        RepositoryCreateOrgWorker.perform_async('GitHub', org.login)
      end
      true
    rescue *RepositoryHost::Github::IGNORABLE_EXCEPTIONS
      nil
    end

    def download_repos
      api_client.search_repos("user:#{owner.login}").items.each do |repo|
        CreateRepositoryWorker.perform_async('GitHub', repo.full_name)
      end
      true
    rescue *RepositoryHost::Github::IGNORABLE_EXCEPTIONS
      nil
    end

    def download_members
      return unless owner.org?

      api_client.organization_members(owner.login).each do |org|
        RepositoryCreateUserWorker.perform_async('GitHub', org.login)
      end
      true
    rescue *RepositoryHost::Gitlab::IGNORABLE_EXCEPTIONS
      nil
    rescue Octokit::NotFound
      nil
    end

    def self.fetch_user(id_or_login)
      api_client.user(id_or_login)
    rescue *RepositoryHost::Github::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.fetch_org(id_or_login)
      api_client.org(id_or_login)
    rescue *RepositoryHost::Github::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.api_client(token = nil)
      AuthToken.fallback_client(token)
    end

    def self.create_org(org_hash)
      return if org_hash.nil?
      org_hash = org_hash.to_hash.with_indifferent_access
      org = nil
      org_by_id = RepositoryOrganisation.where(host_type: 'GitHub').find_by_uuid(org_hash[:id])
      org_by_login = RepositoryOrganisation.host('GitHub').login(org_hash[:login]).first
      if org_by_id # its fine
        if org_by_id.login.try(:downcase) == org_hash[:login].downcase
          org = org_by_id
        else
          if org_by_login && !org_by_login.download_org_from_host
            org_by_login.destroy
          end
          org_by_id.login = org_hash[:login]
          org_by_id.save!
          org = org_by_id
        end
      elsif org_by_login # conflict
        if fetch_org(org_by_login.login)
          org = org_by_login if org_by_login.uuid == org_hash[:id]
        end
        org_by_login.destroy if org.nil?
      end
      if org.nil?
        org = RepositoryOrganisation.create!(uuid: org_hash[:id], login: org_hash[:login], host_type: 'GitHub')
      end
      org.update(org_hash.slice(:name, :blog, :location, :email, :bio))
      org
    end

    def self.create_user(user_hash)
      return if user_hash.nil?
      user_hash = user_hash.to_hash.with_indifferent_access
      user = nil
      user_by_id = RepositoryUser.where(host_type: 'GitHub').find_by_uuid(user_hash[:id])
      user_by_login = RepositoryUser.host('GitHub').login(user_hash[:login]).first
      if user_by_id # its fine
        if user_by_id.login.try(:downcase) == user_hash[:login].downcase && user_by_id.user_type == user_hash[:type]
          user = user_by_id
        else
          if user_by_login && !user_by_login.download_user_from_host
            user_by_login.destroy
          end
          user_by_id.login = user_hash[:login]
          user_by_id.user_type = user_hash[:type]
          user_by_id.save!
          user = user_by_id
        end
      elsif user_by_login # conflict
        if fetch_user(user_by_login.login)
          user = user_by_login if user_by_login.uuid == user_hash[:id]
        end
        user_by_login.destroy if user.nil?
      end
      if user.nil?
        user = RepositoryUser.create!(uuid: user_hash[:id], login: user_hash[:login], user_type: user_hash[:type], host_type: 'GitHub')
      end
      user.update(user_hash.slice(:name, :company, :blog, :location, :email, :bio))
      user
    end
  end
end
