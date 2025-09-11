# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Report
        # @since 5.0.0
        # Combines a number of other transforms into a one-step way of
        #   outputting a report of specified fields. Optionally,
        #   rows not having any information in a specified set of fields
        #   will be omitted from the report.
        #
        # @example With defaults
        #   # Used in pipeline as:
        #   # transform Report::Fields, fields: %i[id foo baz]
        #   xform = Report::Fields.new(fields: %i[id foo baz])
        #
        #   input = [
        #     {id: "1", foo: "a", bar: "b", baz: "f"},
        #     {id: "2", foo: "a", bar: "b", baz: "f"},
        #     {id: "3", foo: "c", bar: "d", baz: "g"},
        #     {id: "4", foo: "c", bar: nil, baz: nil},
        #     {id: "5", foo: nil, bar: "d", baz: "i"},
        #     {id: "6", foo: "", bar: "", baz: ""},
        #     {id: "7", foo: nil, bar: "d", baz: nil}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {id: "1", foo: "a", baz: "f"},
        #     {id: "2", foo: "a", baz: "f"},
        #     {id: "3", foo: "c", baz: "g"},
        #     {id: "4", foo: "c", baz: nil},
        #     {id: "5", foo: nil, baz: "i"},
        #     {id: "6", foo: "", baz: ""},
        #     {id: "7", foo: nil, baz: nil}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Default filtering (any)
        #   # Used in pipeline as:
        #   # transform Report::Fields,
        #   #   fields: %i[id foo baz],
        #   #   filter_fields: %i[foo baz]
        #   xform = Report::Fields.new(fields: %i[id foo baz],
        #     filter_fields: %i[foo baz])
        #
        #   input = [
        #     {id: "1", foo: "a", bar: "b", baz: "f"},
        #     {id: "2", foo: "a", bar: "b", baz: "f"},
        #     {id: "3", foo: "c", bar: "d", baz: "g"},
        #     {id: "4", foo: "c", bar: nil, baz: nil},
        #     {id: "5", foo: nil, bar: "d", baz: "i"},
        #     {id: "6", foo: "", bar: "", baz: ""},
        #     {id: "7", foo: nil, bar: "d", baz: nil}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {id: "1", foo: "a", baz: "f"},
        #     {id: "2", foo: "a", baz: "f"},
        #     {id: "3", foo: "c", baz: "g"},
        #     {id: "4", foo: "c", baz: nil},
        #     {id: "5", foo: nil, baz: "i"},
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Strict filtering (all)
        #   # Used in pipeline as:
        #   # transform Report::Fields,
        #   #   fields: %i[id foo baz],
        #   #   filter_fields: %i[foo baz],
        #   #   filter_mode: :all
        #   xform = Report::Fields.new(fields: %i[id foo baz],
        #     filter_fields: %i[foo baz], filter_mode: :all)
        #
        #   input = [
        #     {id: "1", foo: "a", bar: "b", baz: "f"},
        #     {id: "2", foo: "a", bar: "b", baz: "f"},
        #     {id: "3", foo: "c", bar: "d", baz: "g"},
        #     {id: "4", foo: "c", bar: nil, baz: nil},
        #     {id: "5", foo: nil, bar: "d", baz: "i"},
        #     {id: "6", foo: "", bar: "", baz: ""},
        #     {id: "7", foo: nil, bar: "d", baz: nil}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {id: "1", foo: "a", baz: "f"},
        #     {id: "2", foo: "a", baz: "f"},
        #     {id: "3", foo: "c", baz: "g"},
        #   ]
        #   expect(result).to eq(expected)
        class Fields
          # @param fields [Symbol, Array<Symbol>] names of fields to include in
          #   report
          # @param filter_fields [nil, Symbol, Array<Symbol>] names of fields to
          #   include in filter determining whether to keep rows based on
          #   whether fields are populated; When nil, no row filtering is done
          # @param filter_mode [:all, :any] how many of the filter fields must
          #   be populated in order to keep the row
          def initialize(fields:, filter_fields: nil, filter_mode: :any)
            @deleter = Delete::FieldsExcept.new(fields: fields)
            return unless filter_fields

            filter_xform = case filter_mode
            when :all then FilterRows::AllFieldsPopulated
            when :any then FilterRows::AnyFieldsPopulated
            end
            @filter = filter_xform.new(action: :keep, fields: filter_fields)
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            deleter.process(row)
            return row unless instance_variable_defined?(:@filter)

            filter.process(row)
          end

          private

          attr_reader :deleter, :filter
        end
      end
    end
  end
end
