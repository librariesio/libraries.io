module RepositoryOwner
  class Bitbucket < Base
    def avatar_url(size = 60)
      "https://bitbucket.org/account/#{owner.login}/avatar/256"
    end

    def repository_url
      "https://bitbucket.org/#{owner.login}"
    end

    def self.fetch_user(id_or_login)
      api_client.get_request "/2.0/users/#{URI.escape(id_or_login)}"
    rescue *RepositoryHost::Github::IGNORABLE_EXCEPTIONS
      nil
    end

    def self.api_client(token = nil)
      BitBucket.new oauth_token: token || ENV['BITBUCKET_KEY']
    end

    def api_client(token = nil)
      self.class.api_client(token)
    end

    def self.create_user(user_hash)
      user_hash = user_hash.to_hash.with_indifferent_access
      user_hash = {
        id: user_hash[:uuid],
        login: user_hash[:username],
        name: user_hash[:display_name],
        blog: user_hash[:website],
        location: user_hash[:location],
        type: user_hash[:type],
        host_type: 'Bitbucket'
      }
      user = nil
      user_by_id = RepositoryUser.host('Bitbucket').find_by_uuid(user_hash[:id])
      user_by_login = RepositoryUser.host('Bitbucket').where("lower(login) = ?", user_hash[:login].try(:downcase)).first
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
        user = RepositoryUser.create!(uuid: user_hash[:id], login: user_hash[:login], user_type: user_hash[:type], host_type: 'Bitbucket')
      end

      user.update(user_hash.slice(:name, :blog, :location))
      user
    end
  end
end
