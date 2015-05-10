class Admin::StatsController < ApplicationController
  newrelic_ignore

  def index
    @new_projects       = stats_for(Project)
    @new_repos          = stats_for(GithubRepository)
    @new_github_users   = stats_for(GithubUser)
    @new_users          = stats_for(User)
    @new_subscriptions  = stats_for(Subscription)
    @new_versions       = stats_for(Version)
    @new_manifests      = stats_for(Manifest)
    @new_repo_subs      = stats_for(RepositorySubscription)
    @new_readmes        = stats_for(Readme)
    @new_repo_deps      = stats_for(RepositoryDependency)
    @new_deps           = stats_for(Dependency)
    @new_orgs           = stats_for(GithubOrganisation)
    @new_contributions  = stats_for(GithubContribution)
    @new_tags           = stats_for(GithubTag)
  end

  def stats_for(klass)
    period = 3.days.ago.beginning_of_day
    klass.where('created_at > ?', period).group("date(created_at)").count.sort_by{|k,v| k }.reverse
  end
end
