require "rails_helper"

RSpec.describe ProjectsController do
  describe "GET #index" do
    before do
      Project.__elasticsearch__.create_index! index: Project.index_name

      create(:project)
      sleep 1
    end

    after do
      Project.__elasticsearch__.client.indices.delete index: Project.index_name
    end

    it "responds successfully with an HTTP 200 status code" do
      get :index
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template("index")
    end
  end

  describe "GET #bus_factor" do
    let!(:project) { create(:project) }
    it "responds successfully with an HTTP 200 status code" do
      get :bus_factor
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it "renders the index template" do
      get :bus_factor
      expect(response).to render_template("bus_factor")
    end

    context "filtered by language" do
      it "responds successfully with an HTTP 200 status code" do
        get :bus_factor, language: 'Ruby'
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end

      it "renders the index template" do
        get :bus_factor, language: 'Ruby'
        expect(response).to render_template("bus_factor")
      end
    end
  end

  describe "GET #unlicensed" do
    let!(:project) { create(:project) }

    before do
      project.platform_class
    end

    it "responds successfully with an HTTP 200 status code" do
      get :unlicensed
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it "renders the index template" do
      get :unlicensed
      expect(response).to render_template("unlicensed")
    end

    context "filtered by platform" do
      it "responds successfully with an HTTP 200 status code" do
        get :unlicensed, platform: 'Rubygems'
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end

      it "renders the index template" do
        get :unlicensed, platform: 'Rubygems'
        expect(response).to render_template("unlicensed")
      end
    end
  end

  describe "GET #deprecated" do
    let!(:project) { create(:project) }

    before do
      project.platform_class
    end

    it "responds successfully with an HTTP 200 status code" do
      get :deprecated
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it "renders the index template" do
      get :deprecated
      expect(response).to render_template("deprecated")
    end

    context "filtered by platform" do
      it "responds successfully with an HTTP 200 status code" do
        get :deprecated, platform: 'Rubygems'
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end

      it "renders the index template" do
        get :deprecated, platform: 'Rubygems'
        expect(response).to render_template("deprecated")
      end
    end
  end

  describe "GET #removed" do
    let!(:project) { create(:project) }

    before do
      project.platform_class
    end

    it "responds successfully with an HTTP 200 status code" do
      get :removed
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it "renders the index template" do
      get :removed
      expect(response).to render_template("removed")
    end

    context "filtered by platform" do
      it "responds successfully with an HTTP 200 status code" do
        get :removed, platform: 'Rubygems'
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end

      it "renders the index template" do
        get :removed, platform: 'Rubygems'
        expect(response).to render_template("removed")
      end
    end
  end

  describe "GET #unmaintained" do
    let!(:project) { create(:project) }

    before do
      project.platform_class
    end

    it "responds successfully with an HTTP 200 status code" do
      get :unmaintained
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end

    it "renders the index template" do
      get :unmaintained
      expect(response).to render_template("unmaintained")
    end

    context "filtered by platform" do
      it "responds successfully with an HTTP 200 status code" do
        get :unmaintained, platform: 'Rubygems'
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end

      it "renders the index template" do
        get :unmaintained, platform: 'Rubygems'
        expect(response).to render_template("unmaintained")
      end
    end
  end
end
