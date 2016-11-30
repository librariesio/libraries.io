require "rails_helper"

describe "Admin::GithubRepositoriesController" do
  let(:user) { create :user }

  describe "GET /admin/github_repositories", :vcr, type: :request do
    it "denies access when logged out" do
      get admin_github_repositories_path
      expect(response).to redirect_to(login_path)
    end

    it "denies access for non-admins" do
      login(user)
      expect { visit admin_github_repositories_path }.to raise_exception ActiveRecord::RecordNotFound
    end

    it "renders successfully for admins" do
      mock_is_admin
      login(user)
      visit admin_github_repositories_path
      expect(page).to have_content 'Unlicensed Github repos'
    end
  end

  describe "GET /admin/github_repositories/deprecated", :vcr, type: :request do
    it "denies access when logged out" do
      get deprecated_admin_github_repositories_path
      expect(response).to redirect_to(login_path)
    end

    it "denies access for non-admins" do
      login(user)
      expect { visit deprecated_admin_github_repositories_path }.to raise_exception ActiveRecord::RecordNotFound
    end

    it "renders successfully for admins" do
      mock_is_admin
      login(user)
      visit deprecated_admin_github_repositories_path
      expect(page).to have_content 'Deprecated Github repos'
    end
  end

  describe "GET /admin/github_repositories/unmaintained", :vcr, type: :request do
    it "denies access when logged out" do
      get unmaintained_admin_github_repositories_path
      expect(response).to redirect_to(login_path)
    end

    it "denies access for non-admins" do
      login(user)
      expect { visit unmaintained_admin_github_repositories_path }.to raise_exception ActiveRecord::RecordNotFound
    end

    it "renders successfully for admins" do
      mock_is_admin
      login(user)
      visit unmaintained_admin_github_repositories_path
      expect(page).to have_content 'Unmaintained Github repos'
    end
  end

  describe "GET /admin/github_repositories/:id", :vcr, type: :request do
    let(:github_repository) { create(:github_repository) }

    it "denies access when logged out" do
      get admin_github_repository_path(github_repository.id)
      expect(response).to redirect_to(login_path)
    end

    it "denies access for non-admins" do
      login(user)
      expect { visit admin_github_repository_path(github_repository.id) }.to raise_exception ActiveRecord::RecordNotFound
    end

    it "renders successfully for admins" do
      mock_is_admin
      login(user)
      visit admin_github_repository_path(github_repository.id)
      expect(page).to have_content github_repository.full_name
    end
  end
end
