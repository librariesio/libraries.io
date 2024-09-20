# frozen_string_literal: true

# The RateLimitService allows you to run a named item at most N
# times per second, and if the rate limit is exceeded, it raises
# OverLimitError instead of running the block. If OverLimitError
# is raised, the error includes a seconds_to_wait field telling
# you how long you need to wait before you retry (based on how
# many times we already tried to run the named item in the current
# window). The count of how many times we've run already is kept
# in Redis so it's shared across jobs and threads.

class RateLimitService
  class OverLimitError < StandardError; end

  # @param [String] what_to_limit
  # @param [Integer] limit the limit
  # @param [Integer] period the period in seconds, e.g. 3.seconds or 5.minutes
  def initialize(what_to_limit:, limit: nil, period: nil)
    @what_to_limit = what_to_limit
    @limit = limit
    @period = period
  end

  # Call `rate_limited { block }`, if the rate limit is exceeded
  # it raises OverLimitError without running the block, otherwise
  # runs the block.
  #
  # Using the pattern from https://redis.com/redis-best-practices/basic-rate-limiting/
  def rate_limited
    if @limit.nil?
      yield
    else
      time = Time.current.to_i
      current_period = time / @period
      key = "rate_limit:#{@what_to_limit}:#{current_period}"

      (incr_result, _expire_result) = REDIS.multi do |pipeline|
        # increment this period's count (sets key to 1 if it did not exist)
        pipeline.incr(key)
        # ensure expiry is length of period (NOTE: this means keys can possibly stick around twice as long as the period)
        pipeline.expire(key, @period)
      end

      exceeded_by = incr_result - @limit
      if exceeded_by.positive?
        raise OverLimitError, "Rate limit for '#{@what_to_limit}' of #{@limit} per #{@period} seconds exceeded by #{exceeded_by}"
      else
        yield
      end
    end
  end
end
