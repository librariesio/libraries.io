# frozen_string_literal: true
require "rails_helper"

describe "ErrorsController" do
  describe "GET /404", type: :request do
    it "renders successfully when logged out" do
      visit '/404'
      expect(page).to have_content "We can't find whatever it was you were looking for."
    end
  end

  describe "GET /422", type: :request do
    it "renders successfully when logged out" do
      visit '/422'
      expect(page).to have_content "Nope. Couldn't understand a word of that."
    end
  end

  describe "GET /500", type: :request do
    it "renders successfully when logged out" do
      visit '/500'
      expect(page).to have_content "Oh no!  We've had a problem at our end."
    end
  end
end
