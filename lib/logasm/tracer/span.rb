class Logasm
  class Tracer
    # https://github.com/opentracing/opentracing-ruby/blob/master/lib/opentracing/span.rb
    class Span
      attr_reader :context

      attr_writer :operation_name

      def initialize(context, operation_name, logger, start_time: Time.now, tags: {})
        @context = context
        @operation_name = operation_name
        @logger = logger
        @start_time = start_time
        @tags = tags
        @logger.info "Span [#{@operation_name}] started", trace_information
      end

      # Set a tag value on this span
      #
      # @param key [String] the key of the tag
      # @param value [String, Numeric, Boolean] the value of the tag. If it's not
      # a String, Numeric, or Boolean it will be encoded with to_s
      def set_tag(key, value)
        @tags = @tags.merge(key => value)
      end

      # Set a baggage item on the span
      #
      # @param key [String] the key of the baggage item
      # @param value [String] the value of the baggage item
      def set_baggage_item(key, value)
        self
      end

      # Get a baggage item
      #
      # @param key [String] the key of the baggage item
      #
      # @return Value of the baggage item
      def get_baggage_item(key)
        nil
      end

      # Add a log entry to this span
      #
      # @param event [String] event name for the log
      # @param timestamp [Time] time of the log
      # @param fields [Hash] Additional information to log
      def log(event: nil, timestamp: Time.now, **fields)
        @logger.info "Span [#{@operation_name}] #{event}", trace_information.merge(fields)
      end

      # Finish the {Span}
      #
      # @param end_time [Time] custom end time, if not now
      def finish(end_time: Time.now)
        @logger.info "Span [#{@operation_name}] finished", trace_information(
          execution_time: end_time - @start_time
        )
      end

      # @deprecated This is not in OpenTracing API. It will be removed soon.
      def to_h
        trace_information
      end

      private

      def trace_information(additional_fields = {})
        {
          trace: {
            id: @context.trace_id,
            parent_id: @context.parent_id,
            span_id: @context.span_id,
            operation_name: @operation_name
          }.merge(additional_fields).merge(@tags)
        }
      end
    end
  end
end
