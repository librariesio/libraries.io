# frozen_string_literal: true

class StringUtils
  def self.strip_null_bytes(str)
    str.gsub("\u0000", "")
  end
end
