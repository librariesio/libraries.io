class WebHooksController < ApplicationController
  before_action :ensure_logged_in
  before_action :load_repo

  def index
    @web_hooks = @github_repository.web_hooks.paginate(page: params[:page])
  end

  def new
    @web_hook = @github_repository.web_hooks.build
  end

  def create
    @web_hook = @github_repository.web_hooks.build(web_hook_params)
    if @web_hook.save
      redirect_to github_repository_web_hooks_path(@github_repository.owner_name, @github_repository.project_name), notice: 'Web hook created'
    else
      render :new
    end
  end

  def test
    @web_hook = @github_repository.web_hooks.find(params[:id])
    @web_hook.send_test_payload
    redirect_to github_repository_web_hooks_path(@github_repository.owner_name, @github_repository.project_name), notice: 'Web hook test sent'
  end

  def edit
    @web_hook = @github_repository.web_hooks.find(params[:id])
  end

  def update
    @web_hook = @github_repository.web_hooks.find(params[:id])
    if @web_hook.update_attributes(web_hook_params)
      redirect_to github_repository_web_hooks_path(@github_repository.owner_name, @github_repository.project_name), notice: 'Web hook updated'
    else
      render :edit
    end
  end

  def destroy
    @web_hook = @github_repository.web_hooks.find(params[:id])
    @web_hook.destroy
    redirect_to github_repository_web_hooks_path(@github_repository.owner_name, @github_repository.project_name), notice: 'Web hook deleted'
  end

  private

  def web_hook_params
    params.require(:web_hook).permit(:url)
  end

  def authorized?
    current_user.can_read?(@github_repository)
  end
end
