# frozen_string_literal: true

# Fetches a list of all Projects that are lifted, via the Tidelift API.
class FetchLiftedProjects
  class MissingApiKey < StandardError; end

  class BadResponse < StandardError
    def initialize(status, page)
      super("FetchLiftedProjects received a #{status} code on page #{page}")
    end
  end

  def run
    raise MissingApiKey if Rails.configuration.tidelift_api_key.blank?

    current_page = 1
    results = []
    while !current_page.nil? && current_page < 1000 # failsafe
      resp = Typhoeus.get("https://api.tidelift.com/external-api/packages?lifted=true&page=#{current_page}&per_page=100", headers: { "Authorization" => "Bearer #{Rails.configuration.tidelift_api_key}" })

      raise BadResponse.new(resp.response_code, current_page) if resp.response_code != 200

      json = JSON.parse(resp.body)
      current_page = json["next_page"]
      results += json["results"]
    end

    results
      .map { |result| Project.find_best(result["platform"], result["name"]) }
      .compact
  end
end
