class ExploreController < ApplicationController
  def index
    @platforms = Project.popular_platforms(:facet_limit => 40).first(28)
    @keywords = Project.popular_keywords(:facet_limit => 40).first(15)
    @languages = Project.popular_languages(:facet_limit => 40).first(21)
    @licenses = Project.popular_licenses(:facet_limit => 40).first(10)

    project_scope = Project.includes(:repository).maintained.with_description

    @trending_projects = project_scope.recently_created.hacker_news.limit(20).to_a.uniq(&:name).first(10)
    @new_projects = project_scope.order('projects.created_at desc').limit(10)
  end
end
