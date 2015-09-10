class Admin::StatsController < Admin::ApplicationController
  newrelic_ignore

  def index
    @recent_users = User.order('created_at DESC').limit(19)

    @new_projects       = stats_for(Project)
    @new_github_users   = stats_for(GithubUser)
    @new_users          = stats_for(User)
    @new_subscriptions  = stats_for(Subscription)
    @new_versions       = stats_for(Version)
    @new_manifests      = stats_for(Manifest)
    @new_repo_subs      = stats_for(RepositorySubscription)
    @new_readmes        = stats_for(Readme)
    @new_orgs           = stats_for(GithubOrganisation)
  end

  def stats_for(klass)
    period = 3.days.ago.beginning_of_day
    klass.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
  end
end
