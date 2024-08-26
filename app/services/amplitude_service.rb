# frozen_string_literal: true

class AmplitudeService
  # API Docs: https://www.docs.developers.amplitude.com/analytics/apis/http-v2-api/
  HTTP_V2_URL = "https://api2.amplitude.com/2/httpapi"
  BLOCK_LIST_PATH = Rails.root.join("lib", "amplitude_block_list.txt")

  EVENTS = {
    page_viewed: "Page Viewed",
    login_successful: "Login Successful",
    account_updated: "Account Updated",
    account_deleted: "Account Deleted",
  }.freeze

  def self.request_ip
    Current.amplitude_request_ip
  end

  def self.request_ip=(ip)
    Current.amplitude_request_ip = ip
  end

  def self.event(event_type:, event_properties:, user:, request_data:)
    validate_event_type!(event_type)
    track(event_type, event_properties, user, request_data)
  end

  def self.enabled_for_request?
    return false unless Rails.configuration.amplitude_enabled
    return false unless Rails.configuration.amplitude_api_key.present?

    cidrs = load_cidrs
    ip_addr = IPAddr.new(request_ip)
    cidrs.none? { |cidr| cidr.include?(ip_addr) }
  end

  private_class_method def self.track(event_type, event_properties, user, request_data)
    request_data ||= {}
    # Amplitude needs either user_id or device_id. Exit if we have neither.
    return if user.nil? && request_data[:device_id].nil?

    timestamp_ms = (Time.current.to_f * 1000).to_i
    user_agent = request_data[:user_agent] || "libraries.io"

    event = {
      **request_data,
      user_id: pad_user_id(user&.id),
      event_type: event_type,
      time: timestamp_ms,
      event_properties: event_properties,
      user_properties: {
        id: user&.id,
        email: user&.email,
      },
    }

    if enabled_for_request?
      Typhoeus.post(
        HTTP_V2_URL,
        headers: {
          "Content-Type" => "application/json",
          # pass through the User-Agent to allow amplitude-side bot filtering
          "User-Agent" => user_agent,
        },
        body: JSON.dump(
          {
            api_key: Rails.configuration.amplitude_api_key,
            events: [event],
          }
        )
      )
    else
      StructuredLog.capture(
        "AMPLITUDE_MOCK_EVENT",
        {
          class_name: "AmplitudeService",
          event: event,
        }
      )
    end
  rescue StandardError => e
    # don't allow analytics to break the app
    Bugsnag.notify(e)
  end

  private_class_method def self.validate_event_type!(event_type)
    is_valid = EVENTS.value?(event_type)

    unless is_valid
      raise ArgumentError, "event type '#{event_type}' is invalid"
    end

    is_valid
  end

  # The User IDs stored on Amplitude are at least 6 characters long and are
  # padded with 0s if needed.
  private_class_method def self.pad_user_id(user_id)
    user_id&.to_s&.rjust(6, "0")
  end

  private_class_method def self.load_cidrs
    @load_cidrs ||= begin # rubocop:disable Style/RedundantBegin
      File
        .readlines(BLOCK_LIST_PATH)
        .map do |line|
          line.strip!
          next if line.start_with?("#")

          IPAddr.new(line)
        rescue IPAddr::InvalidAddressError
          nil
        end
        .compact
    end
  end
end
