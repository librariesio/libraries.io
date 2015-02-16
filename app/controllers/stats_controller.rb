class StatsController < ApplicationController
  def index
    @new_projects = Project.where('created_at > ?', 1.week.ago).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_versions = Version.where('created_at > ?', 1.week.ago).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_repos = GithubRepository.where('created_at > ?', 1.week.ago).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_users = GithubUser.where('created_at > ?', 1.week.ago).group("date(created_at)").count.sort_by{|k,v| k }.reverse
    @new_contributions = GithubContribution.where('created_at > ?', 1.week.ago).group("date(created_at)").count.sort_by{|k,v| k }.reverse
  end
end
