# frozen_string_literal: true

# Sidekiq middleware to send traces to Stackdriver, based off the Stackdriver/GoogleCloudTrace
# middleware: https://github.com/googleapis/google-cloud-ruby/blob/master/google-cloud-trace/lib/google/cloud/trace/middleware.rb
#
# Sidekiq.configure_server do |config|
#   config.server_middleware do |chain|
#     chain.add Sidekiq::GoogleCloudTraceMiddleware, project_id: YOUR_GCLOUD_PROJECT_ID
#   end
# end
module Sidekiq
  class GoogleCloudTraceMiddleware
    ##
    # The name of this trace agent as reported to the Stackdriver backend.
    AGENT_NAME = "ruby #{Google::Cloud::Trace::VERSION}"

    def initialize(options = {})
      raise ArgumentError, "project_id missing" unless options[:project_id].present?

      @project_id = options[:project_id]
      tracer = Google::Cloud::Trace.new(project_id: @project_id, credentials: nil)
      @service = Google::Cloud::Trace::AsyncReporter.new tracer.service
    end

    def call(_worker, job, _queue)
      job_name = "sidekiq:#{job['class'].underscore}"
      trace_context = Stackdriver::Core::TraceContext.new(sampled: true, capture_stack: true)
      trace = Google::Cloud::Trace::TraceRecord.new @project_id, trace_context

      begin
        Google::Cloud::Trace.set trace
        Google::Cloud::Trace.in_span job_name do |span|
          configure_span span, job_name
          yield
        end
      ensure
        Google::Cloud::Trace.set nil
        send_trace trace
      end
    end

    private

    ##
    # Send the given trace to the trace service, if requested.
    #
    # @private
    # @param [Google::Cloud::Trace::TraceRecord] trace The trace to send.
    #
    def send_trace(trace)
      if @service && trace.trace_context.sampled?
        begin
          @service.patch_traces trace
        rescue StandardError => e
          ::Rails.logger.error "Transmit to Stackdriver Trace failed: #{e.inspect}"
        end
      end
    end

    ##
    # Configures the root span for this job.
    #
    # @private
    # @param [Google::Cloud::Trace::TraceSpan] span The root span to
    #     configure.
    #
    def configure_span(span, job_name)
      span.name = job_name
      span.labels[Google::Cloud::Trace::LabelKey::AGENT] = AGENT_NAME
      span.labels[Google::Cloud::Trace::LabelKey::PID] = ::Process.pid.to_s
      span.labels[Google::Cloud::Trace::LabelKey::TID] = ::Thread.current.object_id.to_s

      span
    end
  end
end
