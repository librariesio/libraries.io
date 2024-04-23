# frozen_string_literal: true

require "pry"
require "simplecov"
require "custom_matchers"
SimpleCov.start "rails"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before :all do
    Scenic.database.refresh_materialized_view("project_dependent_repositories", concurrently: false, cascade: false)
  end

  config.around :each, elasticsearch: true do |example|
    [Project].each do |model|
      model.__elasticsearch__.create_index!({ force: true })
      model.__elasticsearch__.import({ force: true })
    end
    example.run
    [Project].each do |model|
      model.__elasticsearch__.client.indices.delete index: model.index_name
    end
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.include(CustomMatchers)
end
