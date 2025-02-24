# frozen_string_literal: false

class Array
  # Generates a single quoted postgres array string format. This is the format used
  # to insert or update stuff in the database.
  def to_postgres_array(omit_quotes: false)
    result = "#{omit_quotes ? '' : "'"}{"

    result << collect do |value|
      case value
      when Array
        value.to_postgres_array(omit_quotes: true)
      when String
        value = value.gsub(/\\/, '\&\&')
        value = value.gsub(/'/, "''")
        value = value.gsub(/"/, '\"')
        value = "\"#{value}\""
        value
      when NilClass
        "NULL"
      else
        value
      end
    end.join(",")

    result << "}#{omit_quotes ? '' : "'"}"
  end

  # If the method from_postgres_array is called in an Array, it just returns self.
  def from_postgres_array(_base_type = :string)
    self
  end
end
