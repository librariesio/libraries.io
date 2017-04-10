module RepositoryOwner
  class Gitlab < Base
    def avatar_url(size = 60)
      "https://gitlab.com/uploads/user/avatar/#{owner.uuid}/avatar.png"
    end

    def repository_url
      "https://gitlab.com/#{owner.login}"
    end

    def self.fetch_user(id_or_login)
      api_client.user(id_or_login)
    rescue *RepositoryHost::Github::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.api_client(token = nil)
      ::Gitlab.client(endpoint: 'https://gitlab.com/api/v3', private_token: token || ENV['GITLAB_KEY'])
    end

    def api_client(token = nil)
      self.class.api_client(token)
    end

    def self.create_user(user_hash)
      user_hash = user_hash.to_hash.with_indifferent_access
      user_hash = {
        id: user_hash[:id],
        login: user_hash[:username],
        name: user_hash[:name],
        blog: user_hash[:website_url],
        location: user_hash[:location],
        bio: user_hash[:bio],
        type: 'User',
        host_type: 'GitLab'
      }
      user = nil
      user_by_id = RepositoryUser.host('GitLab').find_by_uuid(user_hash[:id])
      user_by_login = RepositoryUser.host('GitLab').where("lower(login) = ?", user_hash[:login].try(:downcase)).first
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
        if user_by_login.download_user_from_host_by_login
          user = user_by_login if user_by_login.uuid == user_hash[:id]
        end
        user_by_login.destroy if user.nil?
      end
      if user.nil?
        user = RepositoryUser.create!(uuid: user_hash[:id], login: user_hash[:login], user_type: user_hash[:type], host_type: 'GitLab')
      end

      user.update(user_hash.slice(:name, :blog, :location))
      user
    end

  end
end
