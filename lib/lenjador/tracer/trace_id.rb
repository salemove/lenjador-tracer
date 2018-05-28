class Lenjador
  class Tracer
    module TraceId
      TRACE_ID_UPPER_BOUND = 2 ** 64

      # Generates 64-bit lower-hex encoded ID. This was chosen to be compatible
      # with tracing frameworks like zipkin.
      def self.generate
        rand(TRACE_ID_UPPER_BOUND).to_s(16)
      end
    end
  end
end
