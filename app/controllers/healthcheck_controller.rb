# frozen_string_literal: true

class HealthcheckController < ApplicationController
  def index
    render plain: "OK\nRevision: #{Rails.application.config.git_revision}"
  end
end
