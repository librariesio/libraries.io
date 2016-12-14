require "rails_helper"

describe "WebHooksController", :vcr do
  let(:user) { create :user }
  let(:random_user) { create :user }
  let(:github_repository) { create(:github_repository) }
  let!(:repository_permission) { create(:repository_permission, user: user, github_repository: github_repository)}
  let(:web_hook) { create(:web_hook, github_repository: github_repository) }

  describe "GET /github/:owner/:name/web_hooks", type: :request do
    it "denies access when logged out" do
      get github_repository_web_hooks_path(github_repository.owner_name, github_repository.project_name)
      expect(response).to redirect_to(login_path)
    end

    it "denies access when user doesnt have pull access to repo" do
      login(random_user)
      get github_repository_web_hooks_path(github_repository.owner_name, github_repository.project_name)
      expect(response).to redirect_to(login_path)
    end

    it "renders successfully for logged in users" do
      login(user)
      visit github_repository_web_hooks_path(github_repository.owner_name, github_repository.project_name)
      expect(page).to have_content 'Web Hooks'
    end
  end

  describe "GET /github/:owner/:name/web_hooks/new", type: :request do
    it "denies access when logged out" do
      get new_github_repository_web_hook_path(github_repository.owner_name, github_repository.project_name)
      expect(response).to redirect_to(login_path)
    end

    it "denies access when user doesnt have pull access to repo" do
      login(random_user)
      get github_repository_web_hooks_path(github_repository.owner_name, github_repository.project_name)
      expect(response).to redirect_to(login_path)
    end

    it "renders successfully for logged in users" do
      login(user)
      visit new_github_repository_web_hook_path(github_repository.owner_name, github_repository.project_name)
      expect(page).to have_content 'New Web Hook'
    end
  end

  describe "GET /github/:owner/:name/web_hooks/:id/edit", type: :request do
    it "denies access when logged out" do
      get edit_github_repository_web_hook_path(github_repository.owner_name, github_repository.project_name, web_hook.id)
      expect(response).to redirect_to(login_path)
    end

    it "denies access when user doesnt have pull access to repo" do
      login(random_user)
      get edit_github_repository_web_hook_path(github_repository.owner_name, github_repository.project_name, web_hook.id)
      expect(response).to redirect_to(login_path)
    end

    it "renders successfully for logged in users" do
      login(user)
      visit edit_github_repository_web_hook_path(github_repository.owner_name, github_repository.project_name, web_hook.id)
      expect(page).to have_content 'Edit Web Hook'
    end
  end
end
