module GithubIdentity
  def hidden
    github_user.hidden
  end

  def hidden=(val)
    github_user.update_attributes(hidden: val)
  end

  def github_settings_url
    if private_repo_token.present?
      key = ENV['GITHUB_PRIVATE_KEY']
    elsif public_repo_token.present?
      key = ENV['GITHUB_PUBLIC_KEY']
    else
      key = ENV['GITHUB_KEY']
    end
    "https://github.com/settings/connections/applications/#{key}"
  end

  def assign_from_github_auth_hash(hash)
    ignored_fields = new_record? ? [] : %i(email)

    user_hash = {
      uid:         hash.fetch('uid'),
      nickname:    hash.fetch('info', {}).fetch('nickname'),
      email:       hash.fetch('info', {}).fetch('email', nil),
    }

    update_attributes(user_hash.except(*ignored_fields))
  end

  def update_repo_permissions_async
    SyncPermissionsWorker.perform_async(self.id)
  end

  def update_repo_permissions
    self.update_column(:currently_syncing, true)
    download_orgs
    r = github_client.repos

    current_repo_ids = []

    existing_permissions = repository_permissions.all
    new_repo_ids = r.map(&:id)
    existing_repos = GithubRepository.where(github_id: new_repo_ids).select(:id, :github_id)

    r.each do |repo|
      unless github_repo = existing_repos.find{|re| re.github_id == repo.id}
        github_repo = GithubRepository.find_by('lower(full_name) = ?', repo.full_name.downcase) || GithubRepository.create_from_hash(repo)
      end
      next if github_repo.nil?
      current_repo_ids << github_repo.id

      unless rp = existing_permissions.find{|p| p.github_repository_id == github_repo.id}
        rp = repository_permissions.build(github_repository_id: github_repo.id)
      end
      rp.admin = repo.permissions.admin
      rp.push = repo.permissions.push
      rp.pull = repo.permissions.pull
      rp.save! if rp.changed?
    end

    # delete missing permissions
    existing_repo_ids = repository_permissions.pluck(:github_repository_id)
    remove_ids = existing_repo_ids - current_repo_ids
    repository_permissions.where(github_repository_id: remove_ids).delete_all if remove_ids.any?

  rescue *GithubRepository::IGNORABLE_GITHUB_EXCEPTIONS
    nil
  ensure
    self.update_columns(last_synced_at: Time.now, currently_syncing: false)
  end

  def download_self
    GithubUser.create_from_github(OpenStruct.new({id: self.uid, login: self.nickname, type: 'User'}))
    GithubUpdateUserWorker.perform_async(nickname)
  end

  def download_orgs
    github_client.orgs.each do |org|
      GithubCreateOrgWorker.perform_async(org.login)
    end
  rescue *GithubRepository::IGNORABLE_GITHUB_EXCEPTIONS
    nil
  end

  def token
    private_repo_token.presence || public_repo_token.presence || read_attribute(:token)
  end

  def uid
    github_identity.try(:uid).presence || read_attribute(:uid)
  end

  def public_repo_token
    github_public_identity.try(:token).presence || read_attribute(:public_repo_token)
  end

  def github_identity
    identities.find_by_provider('github')
  end

  def github_public_identity
    identities.find_by_provider('githubpublic')
  end

  def private_repo_token
    github_private_identity.try(:token).presence || read_attribute(:private_repo_token)
  end

  def github_private_identity
    identities.find_by_provider('githubprivate')
  end

  def github_client
    AuthToken.new_client(token)
  end

  def avatar_url(size = 60)
    "https://avatars.githubusercontent.com/u/#{uid}?size=#{size}"
  end

  def github_url
    "https://github.com/#{nickname}"
  end
end
