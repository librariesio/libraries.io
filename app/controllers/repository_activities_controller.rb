class RepositoryActivitiesController < ApplicationController
  before_action :load_repo

  def show
    original_scope = @repository.dependency_activities
    scope = original_scope
    scope = original_scope.where(requirement: params[:requirements]) if params[:requirements].present?
    scope = scope.where(action: params[:type]) if params[:type].present?
    @types = original_scope.group(:action).count
    @total = DependencyActivity.where(repository_id: @repository.id).distinct.count(:project_id)

    @activities = scope.includes(:project)
                       .order('committed_at DESC')
                       .paginate(page: page_number, per_page: 20)
    @chart_data = scope.group(:action).group_by_month(:committed_at).count
  end

  private

  helper_method :sort_by_semver_range
  def sort_by_semver_range(limit)
    @all_counts.sort_by{|_k,v| -v}
               .first(limit)
               .sort_by{|k,_v|
                 k.gsub(/\~|\>|\<|\^|\=|\*|\s/,'')
                 .gsub('-','.')
                 .split('.').map{|i| i.to_i}
               }
  end

end
