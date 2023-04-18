# frozen_string_literal: true

require "rails_helper"

describe ActiveRecord do
  describe "with_statement_timeout" do
    it "should run the block with a temporary statement_timeout" do
      before_timeout = ActiveRecord::Base.connection.exec_query("SHOW statement_timeout;").first["statement_timeout"]
      temporary_timeout = ActiveRecord::Base.connection.with_statement_timeout(1234) do
        ActiveRecord::Base.connection.exec_query("SHOW statement_timeout;").first["statement_timeout"]
      end
      after_timeout = ActiveRecord::Base.connection.exec_query("SHOW statement_timeout;").first["statement_timeout"]

      expect(after_timeout).to eq(before_timeout)
      expect(temporary_timeout).to eq("1234s")
    end
  end

  it "should not affect the timeouts of other connections" do
    current_conn = ActiveRecord::Base.connection
    other_conn = ActiveRecord::Base.connection_pool.checkout

    begin
      current_conn.with_statement_timeout(123_456) do |conn|
        expect(conn.get_statement_timeout).to eq("123456s")
        expect(other_conn.get_statement_timeout).to eq("5min")
      end
      expect(current_conn.get_statement_timeout).to eq("5min")
      expect(other_conn.get_statement_timeout).to eq("5min")
    ensure
      ActiveRecord::Base.connection_pool.checkin(other_conn)
    end
  end
end
