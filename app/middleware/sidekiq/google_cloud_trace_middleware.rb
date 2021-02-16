# frozen_string_literal: true

# This file incorporates work covered by the following copyright and permission notice:
#
# Copyright 2016 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "google/cloud/trace"

# Sidekiq middleware to send traces to Stackdriver, based off the Stackdriver/GoogleCloudTrace Rails middleware:
# https://github.com/googleapis/google-cloud-ruby/blob/master/google-cloud-trace/lib/google/cloud/trace/middleware.rb
#
# Usage:
#
# Sidekiq.configure_server do |config|
#   config.server_middleware do |chain|
#     chain.add Sidekiq::GoogleCloudTraceMiddleware, {}
#   end
# end

module Sidekiq
  class GoogleCloudTraceMiddleware
    ##
    # The name of this trace agent as reported to the Stackdriver backend.
    AGENT_NAME = "ruby #{::Google::Cloud::Trace::VERSION}"
    SIDEKIQ_ARGS_LABEL_KEY = "/sidekiq/args"

    def initialize(options = {})
      load_config options

      project_id = configuration.project_id

      if project_id
        credentials = configuration.credentials
        tracer = Google::Cloud::Trace.new project_id: project_id,
                                          credentials: credentials
        @service = Google::Cloud::Trace::AsyncReporter.new tracer.service
      end
    end

    def call(_worker, job, _queue)
      if @service
        trace = create_trace
        job_name = "sidekiq:#{job['class'].underscore}"
        job_args = job["args"]

        begin
          Google::Cloud::Trace.set trace
          Google::Cloud::Trace.in_span job_name do |span|
            configure_span span, job_name, job_args
            yield
          end
        ensure
          Google::Cloud::Trace.set nil
          send_trace trace
        end
      else
        yield
      end
    end

    private

    ##
    # Gets a new trace context for this Sidekiq job.
    # Makes a sampling decision if one has not been made already.
    #
    # @private
    # @return [Stackdriver::Core::TraceContext] The trace context.
    #
    def get_trace_context
      # TimeSampler uses Rack envs to blocklist against request paths, so just pass it an empty env.
      sampled = Google::Cloud::Trace::TimeSampler.default.call({})
      Stackdriver::Core::TraceContext.new \
        sampled: sampled,
        capture_stack: sampled && configuration.capture_stack
    end

    ##
    # Create a new trace for this job.
    #
    def create_trace
      trace_context = get_trace_context
      Google::Cloud::Trace::TraceRecord.new \
        @service.project,
        trace_context,
        span_id_generator: configuration.span_id_generator
    end

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
          Bugsnag.notify(e)
          ::Rails.logger.error "Transmit to Stackdriver Trace failed: #{e.inspect}"
        end
      end
    end

    ##
    # @private Get Google::Cloud::Trace.configure
    def configuration
      Google::Cloud::Trace.configure
    end

    # Consolidate configurations from various sources. Also set
    # instrumentation config parameters to default values if not set
    # already.
    #
    def load_config **kwargs
      capture_stack = kwargs[:capture_stack]
      configuration.capture_stack = capture_stack unless capture_stack.nil?

      sampler = kwargs[:sampler]
      configuration.sampler = sampler unless sampler.nil?

      generator = kwargs[:span_id_generator]
      configuration.span_id_generator = generator unless generator.nil?

      init_default_config
    end

    ##
    # Fallback to default configuration values if not defined already
    def init_default_config
      configuration.project_id ||= Google::Cloud::Trace.default_project_id
      configuration.credentials ||= Google::Cloud.configure.credentials
      configuration.capture_stack ||= false
    end

    ##
    # Configures the root span for this job.
    #
    # @private
    # @param [Google::Cloud::Trace::TraceSpan] span The root span to
    #     configure.
    # @param [String] The job name to use as this span name.
    #
    def configure_span(span, job_name, job_args)
      span.name = job_name
      span.labels[Google::Cloud::Trace::LabelKey::AGENT] = AGENT_NAME
      span.labels[Google::Cloud::Trace::LabelKey::PID] = ::Process.pid.to_s
      span.labels[Google::Cloud::Trace::LabelKey::TID] = ::Thread.current.object_id.to_s
      span.labels[SIDEKIQ_ARGS_LABEL_KEY] = job_args.to_s
      if span.trace.trace_context.capture_stack?
        Google::Cloud::Trace::LabelKey.set_stack_trace span.labels,
                                                       skip_frames: 3
                                                      end

      end

      span
    end
  end
end
