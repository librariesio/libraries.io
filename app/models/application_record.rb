# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.fast_total
    ActiveRecord::Base.count_by_sql "SELECT (reltuples)::bigint FROM pg_class r WHERE relkind = 'r' AND relname = '#{table_name}'"
  end
end
