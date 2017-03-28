class Api::PlatformsController < Api::ApplicationController
  def index
    @platforms = Platform.popular

    render json: @platforms
  end
end
