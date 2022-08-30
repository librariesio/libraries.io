# frozen_string_literal: true
class Admin::RepositoriesController < Admin::ApplicationController
  def show
    @repository = Repository.find(params[:id])
  end

  def update
    @repository = Repository.find(params[:id])
    if @repository.update(repository_params)
      @repository.update_all_info_async
      redirect_to repository_path(@repository.to_param)
    else
      redirect_to admin_repository_path(@repository.id)
    end
  end

  def deprecate
    change(:deprecate!)
  end

  def unmaintain
    change(:unmaintain!)
  end

  def index
    if params[:language].present?
      @language = Linguist::Language[params[:language]].try(:to_s)
      raise ActiveRecord::RecordNotFound if @language.nil?
      scope = Repository.language(@language)
    else
      scope = Repository
    end

    @languages = Repository.maintained.without_license.with_projects.group('repositories.language').count.sort_by(&:last).reverse.first(20)
    @repositories = scope.maintained.without_license.with_projects.order(Arel.sql("COUNT(projects.id) DESC")).group("repositories.id").paginate(page: params[:page])
  end

  def destroy
    @repository = Repository.find(params[:id])
    @repository.destroy
    redirect_to admin_stats_path, notice: 'Repository deleted'
  end

  private

  def repository_params
    params.require(:repository).permit(:license, :status)
  end

  def change(method)
    @repository = Repository.find(params[:id])
    @repository.send(method)
    @repository.update_all_info_async
    redirect_to repository_path(@repository.to_param)
  end
end
