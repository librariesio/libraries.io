# frozen_string_literal: true

class ProjectUsageController < ApplicationController
  before_action :find_project
  def show
    @all_counts = @project.dependents.group("dependencies.requirements").count.select { |k, _v| k.present? }
    @total = @all_counts.sum { |_k, v| v }
    if @all_counts.any?
      @counts = sort_by_semver_range(@all_counts.length > 18 ? 17 : 18)
      @highest_percentage = @counts.map { |_k, v| v.to_f / @total * 100 }.max
    end
  end

  private

  helper_method :sort_by_semver_range
  def sort_by_semver_range(limit)
    @all_counts.sort_by { |_k, v| -v }
      .first(limit)
      .sort_by do |k, _v|
        k.gsub(/~|>|<|\^|=|\*|\s/, "")
          .gsub("-", ".")
          .split(".").map(&:to_i)
      end
  end
end
