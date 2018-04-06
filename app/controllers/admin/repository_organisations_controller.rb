class Admin::RepositoryOrganisationsController < Admin::ApplicationController
  def show
    @org = RepositoryOrganisation.host(current_host).find_by_login(params[:login])
    @top_repos = @org.repositories.open_source.source.order('contributions_count DESC NULLS LAST, rank DESC NULLS LAST').limit(10)
    @total_commits = @org.repositories.map{|r| r.contributions.sum(:count) }.sum
  end
end
