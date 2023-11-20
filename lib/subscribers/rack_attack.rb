# frozen_string_literal: true

ActiveSupport::Notifications.subscribe(/rack_attack/) do |_name, _start, _finish, request_id, payload|
  req = payload[:request]
  match = req.env["rack.attack.matched"]
  match_type = req.env["rack.attack.match_type"]
  match_discriminator = req.env["rack.attack.match_discriminator"].to_s[0, 16] # truncate, could be an api key
  api_key = begin
    req.params["api_key"]
  rescue EOFError # req.params can blow up with bad data
    req.GET["api_key"]
  end
  api_key_id = ApiKey.find_by_access_token(api_key) if api_key

  Rails.logger.info "[RACK_ATTACK] " \
                    "method=#{req.request_method} " \
                    "path=#{req.fullpath} " \
                    "match_type=#{match_type} " \
                    "match=#{match} " \
                    "match_discriminator=#{match_discriminator} " \
                    "request_id=#{request_id} " \
                    "remote_ip=#{req.remote_ip} " \
                    "api_key_id=#{api_key_id&.id || 'nil'}"
end
