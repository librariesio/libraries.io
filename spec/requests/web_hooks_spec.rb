# frozen_string_literal: true

require "rails_helper"

describe "WebHooksController" do
  let(:user) { create :user }
  let(:random_user) { create :user }
  let(:repository) { create(:repository) }
  let!(:repository_permission) { create(:repository_permission, user: user, repository: repository) }
  let(:web_hook) { create(:web_hook, repository: repository) }

  describe "GET /github/:owner/:name/web_hooks", type: :request do
    it "denies access when logged out" do
      get repository_web_hooks_path(repository.to_param)
      expect(response).to redirect_to(login_path)
    end

    it "denies access when user doesnt have pull access to repo" do
      login(random_user)
      get repository_web_hooks_path(repository.to_param)
      expect(response).to redirect_to(login_path)
    end

    it "renders successfully for logged in users" do
      login(user)
      visit repository_web_hooks_path(repository.to_param)
      expect(page).to have_content "Web Hooks"
    end
  end

  describe "GET /github/:owner/:name/web_hooks/new", type: :request do
    it "denies access when logged out" do
      get new_repository_web_hook_path(repository.to_param)
      expect(response).to redirect_to(login_path)
    end

    it "denies access when user doesnt have pull access to repo" do
      login(random_user)
      get repository_web_hooks_path(repository.to_param)
      expect(response).to redirect_to(login_path)
    end

    it "renders successfully for logged in users" do
      login(user)
      visit new_repository_web_hook_path(repository.to_param)
      expect(page).to have_content "New Web Hook"
    end
  end

  describe "GET /github/:owner/:name/web_hooks/:id/edit", type: :request do
    it "denies access when logged out" do
      get edit_repository_web_hook_path(repository.to_param.merge(id: web_hook.id))
      expect(response).to redirect_to(login_path)
    end

    it "denies access when user doesnt have pull access to repo" do
      login(random_user)
      get edit_repository_web_hook_path(repository.to_param.merge(id: web_hook.id))
      expect(response).to redirect_to(login_path)
    end

    it "renders successfully for logged in users" do
      login(user)
      visit edit_repository_web_hook_path(repository.to_param.merge(id: web_hook.id))
      expect(page).to have_content "Edit Web Hook"
    end
  end
end
