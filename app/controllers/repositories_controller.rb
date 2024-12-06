# frozen_string_literal: true

class RepositoriesController < ApplicationController
  def show
    redirect_to redirect_url, status: :moved_permanently
  end

  def sourcerank
    redirect_to redirect_url, status: :moved_permanently
  end

  def tags
    redirect_to redirect_url, status: :moved_permanently
  end

  def contributors
    redirect_to redirect_url, status: :moved_permanently
  end

  def forks
    redirect_to redirect_url, status: :moved_permanently
  end

  def dependencies
    redirect_to redirect_url, status: :moved_permanently
  end

  private

  def redirect_url
    full_name = [ERB::Util.url_encode(params[:owner]), ERB::Util.url_encode(params[:name])].join("/").downcase
    case params[:host_type].try(:downcase)
    when "github"
      "https://github.com/#{full_name}"
    when "gitlab"
      "https://gitlab.com/#{full_name}"
    when "bitbucket"
      "https://bitbucket.com/#{full_name}"
    else
      raise ActiveRecord::RecordNotFound
    end
  end
end
