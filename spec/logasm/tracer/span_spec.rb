
require "spec_helper"

RSpec.describe Logasm::Tracer::Span do
  let(:span) { described_class.new(context, operation_name, logger, start_time: start_time) }

  let(:context) do
    Logasm::Tracer::SpanContext.new(trace_id: trace_id, parent_id: parent_id, span_id: span_id)
  end
  let(:trace_id) { 'trace-id' }
  let(:parent_id) { 'parent-id' }
  let(:span_id) { 'span-id' }
  let(:operation_name) { 'operation-name' }
  let(:logger) { spy('logger') }
  let(:duration_in_seconds) { 10.0 }

  let(:start_time) { Time.local(2017, 5, 1, 22, 10, 00) }
  let(:end_time) { start_time + duration_in_seconds }

  describe '#finish' do
    it 'logs out span information' do
      span.finish(end_time: end_time)
      expect(logger).to have_received(:info).with("Span [#{operation_name}] finished",
        trace: {
          id: trace_id,
          parent_id: parent_id,
          span_id: span_id,
          operation_name: operation_name,
          execution_time: duration_in_seconds
        }
      )
    end
  end
end
