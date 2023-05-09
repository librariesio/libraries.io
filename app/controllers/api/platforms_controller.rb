# frozen_string_literal: true

class Api::PlatformsController < Api::ApplicationController
  def index
    render json: Platform.all
  end
end
