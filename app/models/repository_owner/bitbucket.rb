# frozen_string_literal: true

module RepositoryOwner
  class Bitbucket < Base
    def avatar_url(_size = 60)
      "https://bitbucket.org/account/#{owner.login}/avatar/256"
    end

    def repository_url
      "https://bitbucket.org/#{owner.login}"
    end

    def self.fetch_user(id_or_login)
      begin
        api_client.get_request "/2.0/users/#{Addressable::URI.escape(id_or_login)}"
      rescue BitBucket::Error::NotFound => e
        api_client.get_request "/2.0/teams/#{Addressable::URI.escape(id_or_login)}" if e.message.index("is a team account")
      end
    rescue *RepositoryHost::Bitbucket::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.fetch_org(id_or_login)
      api_client.get_request "/2.0/teams/#{Addressable::URI.escape(id_or_login)}"
    rescue *RepositoryHost::Bitbucket::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.api_client(token = nil)
      BitBucket.new oauth_token: token || Rails.configuration.bitbucket_key
    end

    def api_client(token = nil)
      self.class.api_client(token)
    end

    def download_orgs
      return if owner.org?

      # Bitbucket doesn't have an API to get a users public group memberships so we scrape it instead
      groups_html = PackageManager::Base.get_html("https://bitbucket.org/#{owner.login}/profile/teams")
      links = groups_html.css("li.team a.name").map { |l| l["title"] }

      links.each do |org_name|
        RepositoryCreateOrgWorker.perform_async("Bitbucket", org_name)
      end
      true
    rescue *RepositoryHost::Bitbucket::IGNORABLE_EXCEPTIONS
      nil
    end

    def download_repos
      api_client.get_request("/2.0/repositories/#{owner.login}")["values"].each do |repo|
        CreateRepositoryWorker.perform_async("Bitbucket", repo.full_name)
      end
      true
    rescue *RepositoryHost::Bitbucket::IGNORABLE_EXCEPTIONS
      nil
    end

    def download_members
      return unless owner.org?

      api_client.teams.members(owner.login).each do |org|
        RepositoryCreateUserWorker.perform_async("Bitbucket", org.username)
      end
      true
    rescue *RepositoryHost::Bitbucket::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.create_user(user_hash)
      return if user_hash.nil?

      user_hash = user_hash.to_hash.with_indifferent_access
      user_hash = {
        id: user_hash[:uuid],
        login: user_hash[:username],
        name: user_hash[:display_name],
        blog: user_hash[:website],
        location: user_hash[:location],
        type: user_hash[:type],
        host_type: "Bitbucket",
      }
      user = nil
      user_by_id = RepositoryUser.where(host_type: "Bitbucket").find_by_uuid(user_hash[:id])
      user_by_login = RepositoryUser.host("Bitbucket").login(user_hash[:login]).first
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
      user = RepositoryUser.create!(uuid: user_hash[:id], login: user_hash[:login], user_type: user_hash[:type], host_type: "Bitbucket") if user.nil?

      user.update(user_hash.slice(:name, :blog, :location))
      user
    end

    def self.create_org(org_hash)
      return if org_hash.nil?

      org_hash = org_hash.to_hash.with_indifferent_access
      org_hash = {
        id: org_hash[:uuid],
        login: org_hash[:username],
        name: org_hash[:display_name],
        blog: org_hash[:website],
        location: org_hash[:location],
        type: org_hash[:type],
        host_type: "Bitbucket",
      }
      org = nil
      org_by_id = RepositoryOrganisation.where(host_type: "Bitbucket").find_by_uuid(org_hash[:id])
      org_by_login = RepositoryOrganisation.host("Bitbucket").login(org_hash[:login]).first
      if org_by_id # its fine
        unless org_by_id.login.try(:downcase) == org_hash[:login].downcase
          org_by_login.destroy if org_by_login && !org_by_login.download_org_from_host
          org_by_id.login = org_hash[:login]
          org_by_id.save!
        end
        org = org_by_id
      elsif org_by_login # conflict
        org = org_by_login if fetch_org(org_by_login.login) && (org_by_login.uuid == org_hash[:id])
        org_by_login.destroy if org.nil?
      end
      org = RepositoryOrganisation.create!(uuid: org_hash[:id], login: org_hash[:login], host_type: "Bitbucket") if org.nil?

      org.update(org_hash.slice(:name, :blog, :location))
      org
    end
  end
end
