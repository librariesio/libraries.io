class Api::PlatformsController < Api::ApplicationController
  def index
    raise ActiveRecord::RecordNotFound
    render json: Platform.all
  end
end
