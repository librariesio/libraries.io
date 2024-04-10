# frozen_string_literal: true

class ProjectUsageController < ApplicationController
  before_action :find_project
  def show
    # TODO: can remove this early return if it never gets logged or is not slow anymore
    if @project.dependents_count > 10000
      StructuredLog.capture(
        "PROJECT_USAGE_TOO_MANY_DEPENDENTS", {
          name: @project.name,
          platform: @project.platform,
          dependents_count: @project.dependents_count,
        }
      )
      @too_big = true
      @total = @project.dependents_count
      return
    end
    @all_counts = @project.dependents.group("dependencies.requirements").count.select { |k, _v| k.present? }
    @total = @all_counts.sum { |_k, v| v }
    if @all_counts.any?
      @kinds = @project.dependents.group("dependencies.kind").count
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
