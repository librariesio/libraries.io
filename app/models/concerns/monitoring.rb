module Monitoring
  def has_active_subscription?
    active_subscription.present?
  end

  def current_plan
    @current_plan ||= payola_subscriptions.active.select{|sub| sub.plan.present? }.sort{|sub| sub.plan.amount }.last.try(:plan)
  end

  def active_subscription
    @active_subscription ||= payola_subscriptions.active.select{|sub| sub.plan.present? }.sort{|sub| sub.plan.amount }
  end

  def max_private_repo_count
    current_plan.try(:repo_count) || 0
  end

  def current_private_repo_count
    watched_repositories.where(private: true).count
  end

  def reached_private_repo_limit?
    return false if admin?
    current_private_repo_count >= max_private_repo_count
  end

  def can_enable_private_repo_tracking?
    private_repo_token.blank?
  end

  def can_track_private_repos?
    admin? || has_active_subscription?
  end

  def needs_to_enable_github_access?
    private_repo_token.blank? && public_repo_token.blank?
  end

  def can_watch?(repo)
    return true if admin?
    if repo.private?
      can_track_private_repos? && !reached_private_repo_limit?
    else
      !needs_to_enable_github_access?
    end
  end

  def monitoring_enabled?
    public_repo_token.present? || private_repo_token.present?
  end

  def can_monitor?(repository)
    repository_permissions.where(repository: repository).where(admin: true).any?
  end

  def subscribe_to_repo(repository)
    hook = repository.create_webhook(token)
    repository_subscriptions.find_or_create_by(repository_id: repository.id, hook_id: hook.try(:id))
  end

  def unsubscribe_from_repo(repository)
    sub = subscribed_to_repo?(repository)
    sub.destroy
  end

  def subscribed_to?(project)
    subscriptions.find_by_project_id(project.id)
  end

  def subscribed_to_repo?(repository)
    repository_subscriptions.find_by_repository_id(repository.id)
  end

  def can_read?(repository)
    repository_permissions.where(repository: repository).where(pull: true).any?
  end

  def your_dependent_repos(project)
    ids = really_all_dependencies.where(project_id: project.id).includes(:manifest).map{|dep| dep.manifest.repository_id }
    all_repositories.where(id: ids).order('fork ASC, pushed_at DESC, rank DESC NULLS LAST')
  end
end
