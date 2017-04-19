require 'logasm/tracer/version'
require 'logasm/tracer/span'
require 'logasm/tracer/span_context'
require 'logasm/tracer/trace_id'

class Logasm
  # Implements OpenTracing API
  #
  # See https://github.com/opentracing/opentracing-ruby/blob/master/lib/opentracing.rb
  # and https://github.com/opentracing/opentracing-ruby/blob/master/lib/opentracing/tracer.rb
  class Tracer
    FORMAT_TEXT_MAP = 1
    FORMAT_BINARY = 2
    FORMAT_RACK = 3

    def initialize(logger)
      @logger = logger
    end

    # Starts a new span.
    #
    # @param operation_name [String] The operation name for the Span
    # @param child_of [SpanContext, Span] SpanContext that acts as a parent to
    #        the newly-started Span. If a Span instance is provided, its
    #        context is automatically substituted.
    # @param start_time [Time] When the Span started, if not now
    # @param tags [Hash] Tags to assign to the Span at start time
    #
    # @return [Span] The newly-started Span
    def start_span(operation_name, child_of: nil, start_time: Time.now, tags: {}, **)
      context =
        if child_of
          parent_context = child_of.respond_to?(:context) ? child_of.context : child_of
          SpanContext.create_from_parent_context(parent_context)
        else
          SpanContext.create_parent_context
        end

      Span.new(context, operation_name, @logger, start_time: start_time, tags: tags)
    end

    # Inject a SpanContext into the given carrier
    #
    # @param span_context [SpanContext]
    # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
    # @param carrier [Carrier] A carrier object of the type dictated by the specified `format`
    def inject(span_context, format, carrier)
      case format
      when FORMAT_TEXT_MAP
        carrier['trace-id'] = span_context.trace_id
        carrier['parent-id'] = span_context.parent_id
        carrier['span-id'] = span_context.span_id
      when FORMAT_RACK
        carrier['X-Trace-Id'] = span_context.trace_id
        carrier['X-Trace-Parent-Id'] = span_context.parent_id
        carrier['X-Trace-Span-Id'] = span_context.span_id
      else
        @logger.error "Logasm::Tracer with format #{format} is not supported yet"
      end
    end

    # Extract a SpanContext in the given format from the given carrier.
    #
    # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
    # @param carrier [Carrier] A carrier object of the type dictated by the specified `format`
    # @return [SpanContext] the extracted SpanContext or nil if none could be found
    def extract(format, carrier)
      case format
      when FORMAT_TEXT_MAP
        trace_id = carrier['trace-id']
        parent_id = carrier['parent-id']
        span_id = carrier['span-id']

        if trace_id && span_id
          SpanContext.new(trace_id: trace_id, parent_id: parent_id, span_id: span_id)
        else
          nil
        end
      when FORMAT_RACK
        trace_id = carrier['HTTP_X_TRACE_ID']
        parent_id = carrier['HTTP_X_TRACE_PARENT_ID']
        span_id = carrier['HTTP_X_TRACE_SPAN_ID']

        if trace_id && span_id
          SpanContext.new(trace_id: trace_id, parent_id: parent_id, span_id: span_id)
        else
          nil
        end
      else
        @logger.error "Logasm::Tracer with format #{format} is not supported yet"
        nil
      end
    end
  end
end
