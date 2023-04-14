ActiveSupport::Notifications.subscribe(/rack_attack/) do |name, start, finish, request_id, payload|
  req = payload[:request]
  match = req.env["rack.attack.matched"]
  match_type = req.env["rack.attack.match_type"]
  match_discriminator = req.env["rack.attack.match_discriminator"].to_s[0, 16] # truncate, could be an api key

  Rails.logger.info "[RACK_ATTACK] method=#{req.request_method} path=#{req.fullpath} match_type=#{match_type} match=#{match} match_discriminator=#{match_discriminator} request_id=#{request_id} remote_ip=#{req.remote_ip}"
end
