# frozen_string_literal: true

class String
  def strip_null_bytes
    gsub("\u0000", "")
  end
end
