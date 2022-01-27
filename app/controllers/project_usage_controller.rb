# frozen_string_literal: true
class ProjectUsageController < ApplicationController
  before_action :find_project
  def show
    # looking at repository dependencies is inefficient, let's not DoS ourself
    if @project.dependent_repos_count > 10000
      @too_big = true
      @total = @project.dependent_repos_count
      return
    end
    @all_counts = @project.repository_dependencies.group('repository_dependencies.requirements').count.select{|k,v| k.present? }
    @total = @all_counts.sum{|k,v| v }
    if @all_counts.any?
      @kinds = @project.repository_dependencies.group('repository_dependencies.kind').count
      @counts = sort_by_semver_range(@all_counts.length > 18 ? 17 : 18)
      @highest_percentage = @counts.map{|_k,v| v.to_f/@total*100 }.max
    end
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
