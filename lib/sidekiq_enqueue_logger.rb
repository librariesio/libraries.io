# frozen_string_literal: true

# A client middleware for Sidekiq to log a message whenever a job
# is enqueued.
#
# Sidekiq.configure_server do |config|
#   config.client_middleware do |chain|
#     chain.add SidekiqEnqueueLogger::Middleware::Client
#   end
# end
#
# Sidekiq.configure_client do |config|
#   config.client_middleware do |chain|
#     chain.add SidekiqEnqueueLogger::Middleware::Client
#   end
# end
module SidekiqEnqueueLogger
  module Middleware
    class Client
      include Sidekiq::ServerMiddleware # provides the logger

      def call(_worker, job, _queue, _redis_pool)
        logger.info "enqueue worker=#{job['class']} jid=#{job['jid']} queue=#{job['queue']} is_scheduled=#{job['at'].present?}"
        yield
      end
    end
  end
end
