module GithubIdentity
  def github_enabled?
    token
  end

  def github_user
    return unless github_enabled?
    GithubUser.find_by_github_id(github_identity.uid)
  end

  def hidden
    github_user.try(:hidden)
  end

  def hidden=(val)
    return unless github_user
    github_user.update_attributes(hidden: val)
  end

  def github_settings_url
    if private_repo_token.present?
      key = ENV['GITHUB_PRIVATE_KEY']
    elsif public_repo_token.present?
      key = ENV['GITHUB_PUBLIC_KEY']
    elsif github_token.present?
      key = ENV['GITHUB_KEY']
    else
      return nil
    end
    "https://github.com/settings/connections/applications/#{key}"
  end

  def update_repo_permissions_async
    SyncPermissionsWorker.perform_async(self.id)
  end

  def update_repo_permissions
    return unless token
    self.update_column(:currently_syncing, true)
    download_orgs
    r = github_client.repos

    current_repo_ids = []

    existing_permissions = repository_permissions.all
    new_repo_ids = r.map(&:id)
    existing_repos = Repository.where(uuid: new_repo_ids).select(:id, :uuid)

    r.each do |repo|
      unless github_repo = existing_repos.find{|re| re.uuid.to_s == repo.id.to_s}
        github_repo = Repository.host('GitHub').find_by('lower(full_name) = ?', repo.full_name.downcase) || Repository.create_from_hash(repo)
      end
      next if github_repo.nil?
      current_repo_ids << github_repo.id

      unless rp = existing_permissions.find{|p| p.repository_id == github_repo.id}
        rp = repository_permissions.build(repository_id: github_repo.id)
      end
      rp.admin = repo.permissions.admin
      rp.push = repo.permissions.push
      rp.pull = repo.permissions.pull
      rp.save! if rp.changed?
    end

    # delete missing permissions
    existing_repo_ids = repository_permissions.pluck(:repository_id)
    remove_ids = existing_repo_ids - current_repo_ids
    repository_permissions.where(repository_id: remove_ids).delete_all if remove_ids.any?

  rescue *RepositoryHost::Github::IGNORABLE_EXCEPTIONS
    nil
  ensure
    self.update_columns(last_synced_at: Time.now, currently_syncing: false)
  end

  def download_self
    return unless github_identity
    GithubUser.create_from_github(OpenStruct.new({id: github_identity.uid, login: github_identity.nickname, type: 'User'}))
    GithubUpdateUserWorker.perform_async(nickname)
  end

  def download_orgs
    return unless token
    github_client.orgs.each do |org|
      GithubCreateOrgWorker.perform_async(org.login)
    end
  rescue *RepositoryHost::Github::IGNORABLE_EXCEPTIONS
    nil
  end

  def token
    private_repo_token.presence || public_repo_token.presence || github_token
  end

  def public_repo_token
    github_public_identity.try(:token)
  end

  def github_token
    github_identity.try(:token)
  end

  def github_identity
    identities.find_by_provider('github')
  end

  def github_public_identity
    identities.find_by_provider('githubpublic')
  end

  def private_repo_token
    github_private_identity.try(:token)
  end

  def github_private_identity
    identities.find_by_provider('githubprivate')
  end

  def github_client
    AuthToken.new_client(token)
  end

  def github_url
    "https://github.com/#{nickname}"
  end
end
