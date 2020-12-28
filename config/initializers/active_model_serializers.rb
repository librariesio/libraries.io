# frozen_string_literal: true

module ASMTrace
  def serializable_hash(*)
    if ENV["ASM_TRACING"]
      result = nil
      b = Benchmark.measure { result = super }
      puts "active_model_serializers#serializable_hash##{self.class.name}: #{b.real}ms"
      result
    else
      Google::Cloud::Trace.in_span "active_model_serializers#serializable_hash##{self.class.name}" do |_span|
        super
      end
    end
  end
end

# We're prepending our tracing module to hook into the serializer_hash(render) method of ASM for tracing
ActiveModel::Serializer.prepend(ASMTrace)
ActiveModel::Serializer::ArraySerializer.prepend(ASMTrace)
