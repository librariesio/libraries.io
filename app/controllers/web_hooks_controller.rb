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

  def load_repo
    full_name = [params[:owner], params[:name]].join('/')
    @github_repository = GithubRepository.where('lower(full_name) = ?', full_name.downcase).first
    raise ActiveRecord::RecordNotFound if @github_repository.nil?
    raise ActiveRecord::RecordNotFound unless authorized?
    redirect_to github_repository_path(@github_repository.owner_name, @github_repository.project_name), :status => :moved_permanently if full_name != @github_repository.full_name
  end

  def authorized?
    if @github_repository.private?
      current_user && current_user.can_read?(@github_repository)
    else
      true
    end
  end
end
