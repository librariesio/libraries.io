# frozen_string_literal: true

module StructuredLog
  # Timing example:
  #
  #  StructuredLog.capture(
  #    "SOME_TIMING_METRIC",
  #    {
  #      class_name: "User",
  #      method: "a_slow_method",
  #      some_arbitrary_data: 123,
  #      ms: 123.45,
  #    }
  #  )
  #
  # Error occurrence example:
  #
  #  StructuredLog.capture(
  #    "SOME_ERROR_METRIC",
  #    {
  #      class_name: "Team",
  #      method: "some_erroring_method",
  #      some_arbitrary_data: 123,
  #      message: "A description of the error",
  #    }
  #  )
  #
  def self.capture(name, data_hash)
    log_info(name, data_hash)
  rescue ArgumentError => e
    Rails.logger.error(e.message)
    raise e
  rescue StandardError => e
    Rails.logger.error("Error capturing structured log for metric=#{name} - #{e.message}")
  end

  def self.log_info(name, data_hash)
    if name != name.parameterize(separator: "_").upcase
      raise ArgumentError, "log name should be formatted in UPPERCASE_AND_UNDERSCORES"
    end

    info = ["[#{name}]"]
    cleaned_data_hash = base_data.merge(data_hash).map do |k, v|
      # if the value is a string and doesn't already have quotes around it
      # then add quotes so Datadog interprets the whitespaces in the value as part of the string message
      if v.instance_of?(String) &&
         v.include?(" ") &&
         !(["'", '"'].include?(v.first) && ["'", '"'].include?(v.last))
        "#{k}='#{v}'"
      elsif v.nil?
        "#{k}=nil"
      else
        "#{k}=#{v}"
      end
    end
    Rails.logger.info(info.concat(cleaned_data_hash).join(" "))
  end

  def self.base_data
    {
      env: Rails.env,
    }
  end

  def self.loggable_datetime(time: nil)
    datetime_to_use = time || Time.current
    datetime_to_use.iso8601
  end
end
