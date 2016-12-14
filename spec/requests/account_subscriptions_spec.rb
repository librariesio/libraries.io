require "rails_helper"

describe "AccountSubscriptionsController", :vcr do
  let(:user) { create :user }

  describe "GET /pricing", type: :request do
    it "renders successfully when logged out" do
      visit pricing_path
      expect(page).to have_content 'Pricing'
    end

    it "renders successfully for logged in users" do
      login(user)
      visit pricing_path
      expect(page).to have_content 'Pricing'
    end
  end
end
