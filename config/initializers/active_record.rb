# frozen_string_literal: true

module ActiveRecord
  module WithStatementTimeout
    # Use this for egregious query plans that sometimes exceed our default db statement timeout. It will only affect
    # the current connection, so the rest of the connection pool connections will remain the default.
    # Example: ActiveRecord::Base.connection.with_statement_timeout(500_000) { |conn| puts conn.fetch_statement_timeout }
    def with_statement_timeout(seconds)
      raise "Must pass an integer (in seconds) of timeout" unless seconds.is_a?(Integer)

      execute("SET statement_timeout = '#{seconds * 1000}';")
      yield(self)
    ensure
      execute("SET statement_timeout = '#{ActiveRecord::Base.configurations.dig(Rails.env, 'variables', 'statement_timeout')}';")
    end

    def fetch_statement_timeout
      execute("SHOW statement_timeout;").first["statement_timeout"]
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(ActiveRecord::WithStatementTimeout)
