# frozen_string_literal: true

namespace :amplitude do
  task refresh_block_list: :environment do
    country_codes = %w[ru cn].freeze

    File.open(AmplitudeService::BLOCK_LIST_PATH, "w") do |file|
      file.puts("# This file is generated. To refresh it, execute the following rake task and merge the new file to main.\n# bundle exec amplitude:refresh_block_list\n\n")

      country_codes.each do |country_code|
        url = "https://raw.githubusercontent.com/herrbischoff/country-ip-blocks/master/ipv4/#{country_code}.cidr"
        Rails.logger.info("Fetching '#{url}'")

        response = Typhoeus.get(url)
        if response.success?
          Rails.logger.info("Received #{response.body.lines.length} lines")
          file.puts("# #{country_code}")
          file.puts(response.body)
          file.puts # Empty line between countries
        else
          Rails.logger.error("Failed to fetch data for #{country_code}: #{response.code} #{response.message}")
        end
      end
    end

    Rails.logger.info("Amplitude block list has been written to #{AmplitudeService::BLOCK_LIST_PATH}")
  end
end
