# frozen_string_literal: true

module CustomMatchers
  RSpec::Matchers.define_negated_matcher :not_change, :change

  RSpec::Matchers.define :be_json_string_matching do |expected|
    match do |json_string|
      values_match?(expected, JSON.parse(json_string))
    end

    failure_message do |json_string|
      "Expected json string when parsed to match :\n #{expected}\n\nJSON was: #{JSON.parse(json_string)}"
    end

    failure_message_when_negated do |json_string|
      "Expected json string when parsed NOT to match :\n #{expected}\n\nJSON was: #{JSON.parse(json_string)}"
    end
  end
end
