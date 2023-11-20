# frozen_string_literal: true

module JsonHelper
  def json
    # reparse and never memoize as response may chaneg
    (lambda do
      JSON.parse(response.body)
    end).call
  end

  def json_request_headers
    { "Content-Type" => "application/json", "Accept" => "application/json" }
  end
end

RSpec.configure do |config|
  config.include JsonHelper, type: :request
end
