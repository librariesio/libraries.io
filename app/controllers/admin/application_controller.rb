# frozen_string_literal: true

class Admin::ApplicationController < ApplicationController
  before_action :ensure_logged_in
  before_action :ensure_admin

  private

  def ensure_admin
    raise ActiveRecord::RecordNotFound unless current_user.admin?
  end
end
