# frozen_string_literal: true

require "rails_helper"

describe "Admin::RepositoriesController" do
  let(:user) { create :user }
  let!(:repository) { create :repository }

  describe "GET /admin/repositories", type: :request do
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
      expect(page).to have_content "Unlicensed Repositories"
    end
  end

  describe "GET /admin/repositories/deprecated", type: :request do
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
      expect(page).to have_content "Deprecated Repositories"
    end
  end

  describe "GET /admin/repositories/unmaintained", type: :request do
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
      expect(page).to have_content "Unmaintained Repositories"
    end
  end

  describe "GET /admin/repositories/:id", type: :request do
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
