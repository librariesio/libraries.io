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
    login = ERB::Util.url_encode(params[:login].downcase)
    case params[:host_type].try(:downcase)
    when "github"
      "https://github.com/#{login}"
    when "gitlab"
      "https://gitlab.com/#{login}"
    when "bitbucket"
      "https://bitbucket.com/#{login}"
    else
      raise ActiveRecord::RecordNotFound
    end
  end
end
