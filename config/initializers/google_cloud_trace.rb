# frozen_string_literal: true

# Fake google cloud trace in_span method so we don't have to check our environment
# where we use it
unless Rails.env.production?
  module Google
    module Cloud
      class Trace
        def self.in_span(_span_name)
          yield
        end
      end
    end
  end
end
