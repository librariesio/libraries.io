# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GithubGraphql", type: :service do
  describe "::new_client"
  describe "::parse_query"
  describe "::not_low_rate_remaining"
  describe "::rate_limit_remaining"
end
