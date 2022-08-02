# frozen_string_literal: true

RSpec.configure do |config|
  # Ensure sidekiq is cleared out between examples.
  config.before(:each) do
    Sidekiq::Worker.clear_all
  end
end
