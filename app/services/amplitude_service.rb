# frozen_string_literal: true

class AmplitudeService
  # API Docs: https://www.docs.developers.amplitude.com/analytics/apis/http-v2-api/
  HTTP_V2_URL = "https://api2.amplitude.com/2/httpapi"

  EVENTS = {
    page_viewed: "Page Viewed",
    login_started: "Login Started",
    login_successful: "Login Successful",
    account_updated: "Account Updated",
    account_deleted: "Account Deleted",
  }.freeze

  def self.event(event_type:, event_properties:, user:)
    validate_event_type!(event_type)
    track(event_type, event_properties, user)
  end

  private_class_method def self.track(event_type, event_properties, user)
    timestamp_ms = (Time.current.to_f * 1000).to_i

    event = {
      user_id: pad_user_id(user&.id),
      event_type: event_type,
      time: timestamp_ms,
      event_properties: event_properties,
      user_properties: {
        id: user&.id,
        email: user&.email,
      },
    }

    if Rails.configuration.amplitude_api_key.present?
      Typhoeus.post(
        HTTP_V2_URL,
        headers: { "Content-Type" => "application/json" },
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

  # The User IDs stored on Amplitude are 6 characters long and are padded with
  # 0s if they are any shorter than this.
  private_class_method def self.pad_user_id(user_id)
    user_id&.to_s&.rjust(6, "0")
  end
end
