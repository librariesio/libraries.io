# frozen_string_literal: true

module ActiveRecord
  module WithStatementTimeout
    # Use this for egregious query plans that sometimes exceed our default db statement timeout
    def with_statement_timeout(seconds)
      raise "Must pass an integer (in seconds) of timeout" unless seconds.is_a?(Integer)
      ActiveRecord::Base.connection.execute("SET statement_timeout = '#{seconds * 1000}';")
      yield
    ensure
      ActiveRecord::Base.connection.execute("SET statement_timeout = '#{ActiveRecord::Base.configurations.dig(Rails.env, "variables", "statement_timeout")}';")
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(ActiveRecord::WithStatementTimeout)
