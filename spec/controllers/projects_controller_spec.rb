require "rails_helper"

RSpec.describe ProjectsController do
  describe "GET #index", :vcr do
    before :each do
      @project = create(:project)
      Project.__elasticsearch__.import force: true
      Project.__elasticsearch__.refresh_index!
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

  describe "GET #bus_factor", :vcr do
    before :each do
      @project = create(:project)
      Project.__elasticsearch__.import force: true
      Project.__elasticsearch__.refresh_index!
    end

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
        get :bus_factor, params: { language: 'Ruby' }
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end

      it "renders the index template" do
        get :bus_factor, params: { language: 'Ruby' }
        expect(response).to render_template("bus_factor")
      end
    end
  end

  describe "GET #unlicensed", :vcr do
    before :each do
      @project = create(:project)
      Project.__elasticsearch__.import force: true
      Project.__elasticsearch__.refresh_index!
    end

    before do
      @project.platform_class
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
        get :unlicensed, params: { platform: 'Rubygems' }
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end

      it "renders the index template" do
        get :unlicensed, params: { platform: 'Rubygems' }
        expect(response).to render_template("unlicensed")
      end
    end
  end

  describe "GET #deprecated", :vcr do
    before :each do
      @project = create(:project)
      Project.__elasticsearch__.import force: true
      Project.__elasticsearch__.refresh_index!
    end

    before do
      @project.platform_class
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
        get :deprecated, params: { platform: 'Rubygems' }
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end

      it "renders the index template" do
        get :deprecated, params: { platform: 'Rubygems' }
        expect(response).to render_template("deprecated")
      end
    end
  end

  describe "GET #removed", :vcr do
    before :each do
      @project = create(:project)
      Project.__elasticsearch__.import force: true
      Project.__elasticsearch__.refresh_index!
    end

    before do
      @project.platform_class
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
        get :removed, params: { platform: 'Rubygems' }
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end

      it "renders the index template" do
        get :removed, params: { platform: 'Rubygems' }
        expect(response).to render_template("removed")
      end
    end
  end

  describe "GET #unmaintained", :vcr do
    before :each do
      @project = create(:project)
      Project.__elasticsearch__.import force: true
      Project.__elasticsearch__.refresh_index!
    end

    before do
      @project.platform_class
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
        get :unmaintained, params: { platform: 'Rubygems' }
        expect(response).to be_success
        expect(response).to have_http_status(200)
      end

      it "renders the index template" do
        get :unmaintained, params: { platform: 'Rubygems' }
        expect(response).to render_template("unmaintained")
      end
    end
  end
end
