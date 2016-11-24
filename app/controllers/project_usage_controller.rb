class ProjectUsageController < ApplicationController
  before_action :find_project
  def show
    @all_counts = @project.repository_dependencies.group(:requirements).count
    @total = @all_counts.sum{|k,v| v }
    if @all_counts.any?
      @kinds = @project.repository_dependencies.group(:kind).count
      @counts = @all_counts.sort_by{|_k,v| -v}.first(18).sort_by{|k,_v| k.gsub(/\~|\>|\<|\^|\=|\*|\s/,'').gsub('-','.').split('.').map{|i| i.to_i} }
      @highest_percentage = @counts.map{|_k,v| v.to_f/@total*100 }.max
      scope = @project.dependent_repositories.open_source
      scope = scope.where("repository_dependencies.requirements = ?", params[:requirements]) if params[:requirements].present?
      scope = scope.where("repository_dependencies.kind = ?", params[:kind]) if params[:kind].present?
      @repos = scope.paginate(page: page_number, per_page: 20)
    end
  end
end
