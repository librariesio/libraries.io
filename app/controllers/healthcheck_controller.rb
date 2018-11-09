# frozen_string_literal: true

class HealthcheckController < ApplicationController
  def index
    render plain: "OK"
  end
end
