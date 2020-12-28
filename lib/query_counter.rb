# frozen_string_literal: true

# Count queries in the block provided. Usage:
# count = QueryCounter.count do
#   # Your code here
# end
# puts count
class QueryCounter
  attr_reader :count

  def self.count(&block)
    new.tap do |counter|
      ActiveSupport::Notifications.subscribed(counter.to_proc, "sql.active_record", &block)
    end.count
  end

  def initialize
    @count = 0
  end

  def to_proc
    lambda(&method(:callback))
  end

  def callback(_, _, _, _, values)
    return if %w[CACHE SCHEMA].include?(values[:name])

    @count += 1
  end
end
