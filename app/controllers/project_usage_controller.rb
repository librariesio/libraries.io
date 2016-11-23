class ProjectUsageController < ApplicationController
  before_action :find_project
  def show
    @all_counts = @project.repository_dependencies.group(:requirements).count
    @kinds = @project.repository_dependencies.group(:kind).count
    @total = @all_counts.sum{|k,v| v }
    @counts = @all_counts.sort_by{|k,v| -v}.first(18).sort_by{|k,v| k.gsub(/\~|\>|\<|\^|\=|\*|\s/,'').split('.').map{|v| v.to_i} }
    @highest_percentage = @counts.map{|k,v| v.to_f/@total*100 }.max
    scope = @project.dependent_repositories.open_source
    scope = scope.where("repository_dependencies.requirements = ?", params[:requirements]) if params[:requirements].present?
    @repos = scope.paginate(page: page_number, per_page: 20)
  end
end
