class Api::PlatformsController < Api::ApplicationController
  def index
    render json: Platform.all
  end
end
