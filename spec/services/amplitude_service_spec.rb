# frozen_string_literal: true

require "rails_helper"

RSpec.describe AmplitudeService do
  let(:blocked_ip) { "2.56.24.5" }
  let(:allowed_ip) { "9.56.24.5" }

  before do
    allow(Rails.configuration).to receive(:amplitude_api_key).and_return("dummy_key")
    allow(Rails.configuration).to receive(:amplitude_enabled).and_return(true)
  end

  describe ".event" do
    let(:user) { create(:user, id: 4, email: "user@email.com") }

    let(:event_type) { AmplitudeService::EVENTS[:login_successful] }
    let(:event_properties) do
      {
        name: "Alice",
        occupation: "Time Travel Consultant",
        favorite_color: "Ultraviolet",
      }
    end

    before do
      allow(Typhoeus).to receive(:post)
      described_class.request_ip = allowed_ip
      freeze_time
    end

    let(:timestamp_ms) { (Time.current.to_f * 1000).to_i }

    it "logs an amplitude event" do
      described_class.event(
        event_type: event_type,
        event_properties: event_properties,
        user: user,
        request_data: nil
      )

      expect(Typhoeus).to have_received(:post) { |url, options|
        expect(url).to eq("https://api2.amplitude.com/2/httpapi")

        body = JSON.parse(options[:body]).deep_symbolize_keys
        expect(body).to eq(
          {
            api_key: "dummy_key",
            events: [
              {
                user_id: "000004",
                event_type: "Login Successful",
                time: timestamp_ms,
                event_properties:
                {
                  name: "Alice",
                  occupation: "Time Travel Consultant",
                  favorite_color: "Ultraviolet",
                },
                user_properties:
                {
                  id: 4,
                  email: "user@email.com",
                },
              },
            ],
          }
        )
      }.once
    end

    context "with device_id and no user" do
      let(:user) { nil }

      it "logs an amplitude event with nil user properties" do
        described_class.event(
          event_type: event_type,
          event_properties: event_properties,
          user: user,
          request_data: {
            device_id: "999999",
          }
        )

        expect(Typhoeus).to have_received(:post) { |url, options|
          expect(url).to eq("https://api2.amplitude.com/2/httpapi")

          body = JSON.parse(options[:body]).deep_symbolize_keys
          expect(body).to match(
            {
              api_key: "dummy_key",
              events: [
                {
                  user_id: nil,
                  device_id: "999999",
                  event_type: "Login Successful",
                  time: timestamp_ms,
                  event_properties:
                  {
                    name: "Alice",
                    occupation: "Time Travel Consultant",
                    favorite_color: "Ultraviolet",
                  },
                  user_properties:
                  {
                    id: nil,
                    email: nil,
                  },
                },
              ],
            }
          )
        }.once
      end
    end

    context "with no user and no device_id" do
      it "does not log an amplitude event" do
        described_class.event(
          event_type: event_type,
          event_properties: event_properties,
          user: nil,
          request_data: nil
        )

        expect(Typhoeus).not_to have_received(:post)
      end
    end

    context "with an unknown event_type" do
      let(:event_type) { "Not A Real Event" }

      it "raises ArgumentError" do
        expect do
          described_class.event(
            event_type: event_type,
            event_properties: event_properties,
            user: user,
            request_data: nil
          )
        end.to raise_error(ArgumentError, "event type 'Not A Real Event' is invalid")
      end
    end

    context "with a transient error" do
      before do
        allow(Typhoeus).to receive(:post).and_raise(StandardError)
        allow(Bugsnag).to receive(:notify)
      end

      it "logs the error" do
        expect do
          described_class.event(
            event_type: event_type,
            event_properties: event_properties,
            user: user,
            request_data: nil
          )
        end.not_to raise_error

        expect(Bugsnag).to have_received(:notify).with(StandardError)
      end
    end
  end

  describe ".enabled_for_request?" do
    context "with AMPLITUDE_ENABLED=false" do
      before do
        allow(Rails.configuration).to receive(:amplitude_enabled).and_return(false)
        described_class.request_ip = allowed_ip
      end

      it "returns false" do
        expect(described_class.enabled_for_request?).to be(false)
      end
    end

    context "with AMPLITUDE_API_KEY=nil" do
      before do
        allow(Rails.configuration).to receive(:amplitude_enabled).and_return(false)
        described_class.request_ip = allowed_ip
      end

      it "returns false if AMPLITUDE_API_KEY is missing" do
        expect(described_class.enabled_for_request?).to be(false)
      end
    end

    context "with matching ip" do
      before do
        described_class.request_ip = blocked_ip
      end

      it "returns false" do
        expect(described_class.enabled_for_request?).to be(false)
      end
    end

    context "with non-matching ip" do
      before do
        described_class.request_ip = allowed_ip
      end

      it "returns true" do
        expect(described_class.enabled_for_request?).to be(true)
      end
    end

    context "with no ip" do
      before do
        described_class.request_ip = nil
      end

      it "returns false" do
        expect(described_class.enabled_for_request?).to be(false)
      end
    end
  end
end
