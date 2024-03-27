# frozen_string_literal: true

module GithubIdentity
  def github_enabled?
    token
  end

  def repository_user
    return unless github_enabled?

    @repository_user ||= RepositoryUser.where(host_type: "GitHub").find_by_uuid(github_identity.uid)
  end

  def hidden
    repository_user.try(:hidden)
  end

  def hidden=(val)
    return unless repository_user

    repository_user.update(hidden: val)
  end

  def github_settings_url
    if private_repo_token.present?
      key = Rails.configuration.github_private_key
    elsif public_repo_token.present?
      key = Rails.configuration.github_public_key
    elsif github_token.present?
      key = Rails.configuration.github_key
    else
      return nil
    end
    "https://github.com/settings/connections/applications/#{key}"
  end

  def update_repo_permissions_async
    SyncPermissionsWorker.perform_async(id)
  end

  def update_repo_permissions
    return unless token

    update_column(:currently_syncing, true)
    download_orgs
    r = github_client.repos.map { |repo_data| GithubRepositoryHostDataFactory.generate_from_api(repo_data) }

    current_repo_ids = []

    existing_permissions = repository_permissions.all
    new_repo_ids = r.map(&:id)
    existing_repos = Repository.where(host_type: "GitHub").where(uuid: new_repo_ids).select(:id, :uuid)

    r.each do |repo|
      unless (github_repo = existing_repos.find { |re| re.uuid.to_s == repo.id.to_s })
        github_repo = Repository.host("GitHub").find_by("lower(full_name) = ?", repo.full_name.downcase) || Repository.create_from_data(repo)
      end
      next if github_repo.nil?

      current_repo_ids << github_repo.id
      github_repo.update_all_info_async(token)

      unless (rp = existing_permissions.find { |p| p.repository_id == github_repo.id })
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
    update_columns(last_synced_at: Time.now, currently_syncing: false)
  end

  def download_self
    return unless github_identity

    repository_user = RepositoryUser.create_from_host("GitHub", { id: github_identity.uid, login: github_identity.nickname, type: "User", host_type: "GitHub" })
    if repository_user
      github_identity.update_column(:repository_user_id, repository_user.id)
      RepositoryUpdateUserWorker.perform_async("GitHub", nickname)
    end
  end

  def download_orgs
    return unless token

    github_client.orgs.each do |org|
      RepositoryCreateOrgWorker.perform_async("GitHub", org.login)
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
    identities.find { |i| i.provider == "github" }
  end

  def github_public_identity
    identities.find { |i| i.provider == "githubpublic" }
  end

  def private_repo_token
    github_private_identity.try(:token)
  end

  def github_private_identity
    identities.find { |i| i.provider == "githubprivate" }
  end

  def github_client
    @github_client ||= AuthToken.new_client(token)
  end

  def github_url
    "https://github.com/#{nickname}"
  end
end
