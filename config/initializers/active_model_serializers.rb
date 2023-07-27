# frozen_string_literal: true

require "active_model_serializers"

module ASMTrace
  def serializable_hash(*)
    if ENV["ASM_TRACING"]
      result = nil
      b = Benchmark.measure { result = super }
      puts "active_model_serializers#serializable_hash##{self.class.name}: #{b.real}ms"
      result
    else
      Datadog::Tracing.trace("active_model_serializers#serializable_hash##{self.class.name}") do |_span, _trace|
        super
      end
    end
  end
end

# We're prepending our tracing module to hook into the serializer_hash(render) method of ASM for tracing
ActiveModel::Serializer.prepend(ASMTrace)
ActiveModel::Serializer::ArraySerializer.prepend(ASMTrace)

# Disable logging the "Rendered * with' messages
ActiveSupport::Notifications.unsubscribe(ActiveModelSerializers::Logging::RENDER_EVENT)
