# frozen_string_literal: true

class RepositoryUsersController < ApplicationController
  def show
    redirect_to redirect_url, status: :moved_permanently
  end

  def dependencies
    redirect_to redirect_url, status: :moved_permanently
  end

  def repositories
    redirect_to redirect_url, status: :moved_permanently
  end

  def contributions
    redirect_to redirect_url, status: :moved_permanently
  end

  def projects
    redirect_to redirect_url, status: :moved_permanently
  end

  def contributors
    redirect_to redirect_url, status: :moved_permanently
  end

  private

  def redirect_url
    case params[:host_type].try(:downcase)
    when "github"
      "https://github.com/#{params[:login].downcase}"
    when "gitlab"
      "https://gitlab.com/#{params[:login].downcase}"
    when "bitbucket"
      "https://bitbucket.com/#{params[:login].downcase}"
    else
      raise ActiveRecord::RecordNotFound
    end
  end
end
