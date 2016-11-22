class ProjectUsageController < ApplicationController
  before_action :find_project
  def show
    @counts = @project.repository_dependencies.group(:requirements).count
    @total = @counts.sum{|k,v| v }
    @highest_percentage = @counts.map{|k,v| v.to_f/@total*100 }.max
  end
end
