# frozen_string_literal: true

class EnableUuidExtension < ActiveRecord::Migration[7.1]
  def change
    enable_extension "uuid-ossp"
    enable_extension "pgcrypto"
  end
end
