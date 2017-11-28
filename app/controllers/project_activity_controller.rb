class ProjectActivityController < ApplicationController
  before_action :find_project

  def show
    original_scope = @project.dependency_activities
    scope = original_scope
    scope = original_scope.where(action: params[:type]) if params[:type].present?
    @types = original_scope.group(:action).count
    @total = DependencyActivity.where(project_id: @project.id).distinct.count(:repository_id)

    @activities = scope.includes(:repository)
                       .order('committed_at DESC')
                       .paginate(page: page_number, per_page: 20)
    @chart_data = scope.group(:action).group_by_month(:committed_at).count
  end

end
