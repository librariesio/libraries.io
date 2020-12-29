# frozen_string_literal: true

class Api::BulkProjectController < Api::ApplicationController
  def project_status_queries
    @project_status_queries ||= params[:projects]
      .group_by { |project| project[:platform] }
      .map { |platform, group| ProjectStatusQuery.new(platform, group.map { |p| p[:name] }, includes: @includes) }
  end

  def projects
    project_status_queries
      .map(&:projects_by_name)
      .flat_map(&:values)
  end

  def project_names
    project_status_queries.each_with_object({}) do |psq, result|
      psq.projects_by_name.each do |requested_name, project|
        result[[project.platform, project.name]] = requested_name
      end
    end
  end
end
