class ErrorsController < ApplicationController
  def not_found
    respond_to do |format|
      format.html { render status: 404 }
      format.atom { render xml: "not found", root: "error", status: 404 }
      format.json { render json: { error: "not found" }, status: :not_found }
    end
  end

  def unprocessable
    render status: 422
  end

  def not_acceptable
    respond_to do |format|
      format.html { render status: :not_acceptable }
      format.atom { render xml: "not_acceptable", root: "error", status: :not_acceptable }
      format.json { render json: { error: "not_acceptable" }, status: :not_acceptable }
    end
  end

  def internal
    respond_to do |format|
      format.html { render status: :internal_server_error }
      format.atom { render xml: "internal server error", root: "error", status: :internal_server_error }
      format.json { render json: { error: "internal server error" }, status: :internal_server_error }
    end
  end
end
