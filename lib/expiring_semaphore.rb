# frozen_string_literal: true

# A distributed semaphore, stored in Redis. Uses expiries on the keys
# in case the caller is not able to decrement it for some reason.
# Note that this semaphore returns false instead of blocking.
#
# The TTL is extended everytime the ExpiringSemaphore is interacted
# with, to ensure it exists while callers care about it.
class ExpiringSemaphore
  REDIS_NAMESPACE = "expiring_semaphore"

  attr_reader :key, :size

  # @param [String] name the unique name for this semaphore in Redis.
  # @param [Integer] size the maximum number of times the semaphore
  #   can be acquired.
  # @param [Integer] ttl_seconds the number, in seconds, that the key
  #   will exist. TTL will be extended every time the semaphore
  #   is accessed.
  def initialize(name:, size:, ttl_seconds:)
    @name = name
    @key = "#{REDIS_NAMESPACE}:#{@name}"
    @size = size
    @ttl_seconds = ttl_seconds
  end

  # Acquires a lock in the semaphore if possible.
  #
  # @return [Boolean] returns true if the value was incremented
  #   and false if it was not incremented because the counter
  #   was at the size.
  def acquire
    val = current_value.to_i

    if val >= @size
      false
    else
      REDIS.incrby(@key, 1)
      true
    end
  ensure
    REDIS.expire(@key, @ttl_seconds)
  end

  def release
    val = REDIS.decrby(@key, 1)
    if val < 0
      REDIS.del(@key)
    else
      REDIS.expire(@key, @ttl_seconds)
    end
  end

  def current_value
    REDIS.get(@key)
  end
end
