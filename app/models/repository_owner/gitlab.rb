# frozen_string_literal: true

module RepositoryOwner
  class Gitlab < Base
    def avatar_url(_size = 60)
      "https://gitlab.com/uploads/user/avatar/#{owner.uuid}/avatar.png"
    end

    def repository_url
      "https://gitlab.com/#{owner.login}"
    end

    def self.fetch_user(id_or_login)
      if id_or_login.to_i.to_s == id_or_login.to_s
        api_client.user(id_or_login)
      else
        api_client.get("/users?username=#{id_or_login}").first
      end
    rescue *RepositoryHost::Gitlab::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.fetch_org(id_or_login)
      api_client.group(id_or_login)
    rescue *RepositoryHost::Gitlab::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.api_client(token = nil)
      ::Gitlab.client(endpoint: "https://gitlab.com/api/v4", private_token: token || Rails.configuration.gitlab_key)
    end

    def api_client(token = nil)
      self.class.api_client(token)
    end

    def download_orgs
      return if owner.org?

      # GitLab doesn't have an API to get a users public group memberships so we scrape it instead
      json = get_json("https://gitlab.com/users/#{owner.login}/groups")

      return if json.nil?

      groups_html = Nokogiri::HTML(json["html"])
      return if groups_html.nil?

      links = groups_html.css("a.group-name").map { |l| l["href"][1..] }.compact

      links.each do |org_login|
        RepositoryCreateOrgWorker.perform_async("GitLab", org_login)
      end
      true
    rescue *RepositoryHost::Gitlab::IGNORABLE_EXCEPTIONS
      nil
    end

    def download_repos
      if owner.org?
        repos = api_client.group_projects(owner.login).map(&:path_with_namespace)
      else
        # GitLab doesn't have an API to get a users public projects so we scrape it instead
        json = get_json("https://gitlab.com/users/#{owner.login}/projects")

        return if json.nil?

        projects_html = Nokogiri::HTML(json["html"])
        return if projects_html.nil?

        repos = projects_html.css("a.project").map { |l| l["href"][1..] }.uniq.compact
      end

      repos.each do |repo_name|
        CreateRepositoryWorker.perform_async("GitLab", repo_name)
      end
      true
    rescue *RepositoryHost::Gitlab::IGNORABLE_EXCEPTIONS
      nil
    end

    def download_members
      return unless owner.org?

      api_client.group_members(owner.login).each do |org|
        RepositoryCreateUserWorker.perform_async("GitLab", org.username)
      end
      true
    rescue *RepositoryHost::Gitlab::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.create_user(user_hash)
      return if user_hash.nil?

      user_hash = user_hash.to_hash.with_indifferent_access
      user_hash = {
        id: user_hash[:id],
        login: user_hash[:username],
        name: user_hash[:name],
        blog: user_hash[:website_url],
        location: user_hash[:location],
        bio: user_hash[:bio],
        type: "User",
        host_type: "GitLab",
      }
      user = nil
      user_by_id = RepositoryUser.where(host_type: "GitLab").find_by_uuid(user_hash[:id])
      user_by_login = RepositoryUser.host("GitLab").login(user_hash[:login]).first
      if user_by_id # its fine
        if user_by_id.login.try(:downcase) != user_hash[:login].downcase || user_by_id.user_type != user_hash[:type]
          # If the login has changed, and the new login is taken, destroy the existing record (bc the accounts might have swapped).
          # If the user that used to have this login really exists, it should get re-synced in Repsitory#download_owner eventually.
          user_by_login.destroy if user_by_login && user_by_login != user_by_id
          user_by_id.login = user_hash[:login]
          user_by_id.user_type = user_hash[:type]
          user_by_id.save!
        end
        user = user_by_id
      elsif user_by_login # conflict
        user = user_by_login if fetch_user(user_by_login.login) && (user_by_login.uuid == user_hash[:id])
        user_by_login.destroy if user.nil?
      end
      user = RepositoryUser.create!(uuid: user_hash[:id], login: user_hash[:login], user_type: user_hash[:type], host_type: "GitLab") if user.nil?

      user.update(user_hash.slice(:name, :blog, :location))
      user
    end

    def self.create_org(org_hash)
      return if org_hash.nil?

      org_hash = org_hash.to_hash.with_indifferent_access
      org_hash = {
        id: org_hash[:id],
        login: org_hash[:path],
        name: org_hash[:name],
        blog: org_hash[:website_url],
        location: org_hash[:location],
        bio: org_hash[:bio],
        type: "Organisation",
        host_type: "GitLab",
      }
      org = nil
      org_by_id = RepositoryOrganisation.where(host_type: "GitLab").find_by_uuid(org_hash[:id])
      org_by_login = RepositoryOrganisation.host("GitLab").login(org_hash[:login]).first
      if org_by_id # its fine
        if org_by_id.login.try(:downcase) != org_hash[:login].downcase
          # If the login has changed, and the new login is taken, destroy the existing record (bc the accounts might have swapped).
          # If the org that used to have this login really exists, it should get re-synced in Repsitory#download_owner eventually.
          org_by_login.destroy if org_by_login && org_by_login != org_by_id
          org_by_id.login = org_hash[:login]
          org_by_id.save!
        end
        org = org_by_id
      elsif org_by_login # conflict
        org = org_by_login if fetch_org(org_by_login.login) && (org_by_login.uuid == org_hash[:id])
        org_by_login.destroy if org.nil?
      end
      org = RepositoryOrganisation.create!(uuid: org_hash[:id], login: org_hash[:login], host_type: "GitLab") if org.nil?

      org.update(org_hash.slice(:name, :blog, :location))
      org
    end

    private

    def get_json(url)
      PackageManager::ApiService.request_json_with_headers(url)
    end
  end
end
