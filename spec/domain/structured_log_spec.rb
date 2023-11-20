# frozen_string_literal: true

require "rails_helper"

RSpec.describe StructuredLog do
  it "logs structured data" do
    expect(Rails.logger).to receive(:info).with("[COOL] env=test this=is helpful=maybe")
    described_class.capture("COOL", { this: "is", helpful: "maybe" })
  end

  it "doesn't explode if used poorly" do
    expect(Rails.logger).to receive(:error).with(/Error capturing structured log for/)
    described_class.capture("COOL", 1234)
  end

  it "does not allow names with whitespace" do
    expect { described_class.capture("some name        with whitespaces", {}) }.to raise_error(ArgumentError, a_string_matching("log name"))
  end

  it "renders nil as nil" do
    expect(Rails.logger).to receive(:info).with("[NILCHECK] env=test nilvalue=nil")
    described_class.capture("NILCHECK", { env: "test", nilvalue: nil })
  end

  context "when data hash's value contains whitespace" do
    before do
      allow(Rails.logger).to receive(:info)
    end

    context "when value is not already quoted" do
      it "adds quotes to the values" do
        described_class.capture("LOG_NAME", { one: "o n e ", two: "    t w o    " })
        expect(Rails.logger).to have_received(:info).with("[LOG_NAME] env=test one='o n e ' two='    t w o    '")
      end
    end

    context "when value is already quoted" do
      it "does not add quotes to the values" do
        described_class.capture("LOG_NAME", { one: "'o n e '", two: '"   two   "' })
        expect(Rails.logger).to have_received(:info).with("[LOG_NAME] env=test one='o n e ' two=\"   two   \"")
      end
    end
  end

  describe ".loggable_datetime" do
    before do
      allow(Time).to receive(:current).and_return(Time.at(1_893_553_495, 123, :millisecond, in: "UTC"))
    end

    it "returns the current date & time as a string in iso8601 format" do
      expect(described_class.loggable_datetime).to eq("2030-01-02T03:04:55Z")
    end

    context "when a different Time is passed in" do
      it "returns the input date & time as a string in iso8601 format" do
        input_time = Time.at(1_606_986_306, 321, :millisecond, in: "UTC")

        expect(described_class.loggable_datetime(time: input_time)).to eq("2020-12-03T09:05:06Z")
      end
    end
  end
end
