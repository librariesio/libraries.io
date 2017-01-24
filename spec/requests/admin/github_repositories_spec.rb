require "rails_helper"

describe "Admin::GithubRepositoriesController" do
  let(:user) { create :user }

  describe "GET /admin/repositories", :vcr, type: :request do
    it "denies access when logged out" do
      get admin_repositories_path
      expect(response).to redirect_to(login_path)
    end

    it "denies access for non-admins" do
      login(user)
      expect { visit admin_repositories_path }.to raise_exception ActiveRecord::RecordNotFound
    end

    it "renders successfully for admins" do
      mock_is_admin
      login(user)
      visit admin_repositories_path
      expect(page).to have_content 'Unlicensed Github repos'
    end
  end

  describe "GET /admin/repositories/deprecated", :vcr, type: :request do
    it "denies access when logged out" do
      get deprecated_admin_repositories_path
      expect(response).to redirect_to(login_path)
    end

    it "denies access for non-admins" do
      login(user)
      expect { visit deprecated_admin_repositories_path }.to raise_exception ActiveRecord::RecordNotFound
    end

    it "renders successfully for admins" do
      mock_is_admin
      login(user)
      visit deprecated_admin_repositories_path
      expect(page).to have_content 'Deprecated Github repos'
    end
  end

  describe "GET /admin/repositories/unmaintained", :vcr, type: :request do
    it "denies access when logged out" do
      get unmaintained_admin_repositories_path
      expect(response).to redirect_to(login_path)
    end

    it "denies access for non-admins" do
      login(user)
      expect { visit unmaintained_admin_repositories_path }.to raise_exception ActiveRecord::RecordNotFound
    end

    it "renders successfully for admins" do
      mock_is_admin
      login(user)
      visit unmaintained_admin_repositories_path
      expect(page).to have_content 'Unmaintained Github repos'
    end
  end

  describe "GET /admin/repositories/:id", :vcr, type: :request do
    let(:repository) { create(:repository) }

    it "denies access when logged out" do
      get admin_repository_path(repository.id)
      expect(response).to redirect_to(login_path)
    end

    it "denies access for non-admins" do
      login(user)
      expect { visit admin_repository_path(repository.id) }.to raise_exception ActiveRecord::RecordNotFound
    end

    it "renders successfully for admins" do
      mock_is_admin
      login(user)
      visit admin_repository_path(repository.id)
      expect(page).to have_content repository.full_name
    end
  end
end
