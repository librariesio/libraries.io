# frozen_string_literal: true

require "rails_helper"

describe AuthToken, type: :model do
  it { should validate_presence_of(:token) }

  describe "::new_v4_client" do
    let(:token_value) { Faker::Alphanumeric.alpha }
    subject(:v4_client) { described_class.new_v4_client(token_value) }

    def get_headers_from_client(graphql_client)
      graphql_client.execute.headers(nil)
    end

    it "applies given token to client headers" do
      expect(token_value).to be_present
      expect(get_headers_from_client(v4_client)).to eq({ "Authorization" => "bearer #{token_value}" })
    end
  end
end
