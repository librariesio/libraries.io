class ExploreController < ApplicationController
  def index
    @platforms = Project.popular_platforms(:facet_limit => 40).first(28)
    @keywords = Project.popular_keywords(:facet_limit => 40).first(15)
    @languages = Project.popular_languages(:facet_limit => 40).first(21)
    @licenses = Project.popular_licenses(:facet_limit => 40).first(10)

    project_scope = Project.includes(:repository).maintained.with_description
    repo_scope = Repository.source.with_description.open_source.limit(6)

    @trending_projects = project_scope.recently_created.hacker_news.limit(10).to_a.uniq(&:name).first(6)
    @trending_repos = repo_scope.trending.hacker_news
    @new_projects = project_scope.order('projects.created_at desc').limit(6)
    @new_repos = repo_scope.order('created_at desc')
  end

  private

  helper_method :repo_search
  def repo_search(sort)
    Repository.search('', sort: sort, order: 'desc').paginate(per_page: 6, page: 1).results.map{|result| RepositorySearchResult.new(result) }
  end

  helper_method :project_search
  def project_search(sort)
    Project.search('', sort: sort, order: 'desc').paginate(per_page: 6, page: 1).results.map{|result| ProjectSearchResult.new(result) }
  end
end
