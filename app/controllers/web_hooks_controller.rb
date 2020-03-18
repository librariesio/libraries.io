# frozen_string_literal: true

class WebHooksController < ApplicationController
  before_action :ensure_logged_in
  before_action :load_repo
  before_action :find_web_hook, only: %i[test edit update destroy]

  def index
    @web_hooks = @repository.web_hooks.paginate(page: params[:page])
  end

  def new
    @web_hook = @repository.web_hooks.build
  end

  def create
    @web_hook = @repository.web_hooks.build(web_hook_params)
    if @web_hook.save
      redirect_to repository_web_hooks_path(@repository.to_param), notice: "Web hook created"
    else
      render :new
    end
  end

  def test
    @web_hook.send_test_payload
    redirect_to repository_web_hooks_path(@repository.to_param), notice: "Web hook test sent"
  end

  def update
    if @web_hook.update_attributes(web_hook_params)
      redirect_to repository_web_hooks_path(@repository.to_param), notice: "Web hook updated"
    else
      render :edit
    end
  end

  def destroy
    @web_hook.destroy
    redirect_to repository_web_hooks_path(@repository.to_param), notice: "Web hook deleted"
  end

  private

  def find_web_hook
    @web_hook = @repository.web_hooks.find(params[:id])
  end

  def web_hook_params
    params.require(:web_hook).permit(:url)
  end
end
