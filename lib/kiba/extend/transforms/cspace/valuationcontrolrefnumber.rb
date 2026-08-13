# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Cspace
        # Generates typical pattern of ValuationcontrolRefNumbers based on
        #   year in value date, where available. For each year, the
        #   procedure data is sorted by the full date value, and the
        #   reference number value is incremented.
        #
        # The typical number pattern used is the location record pattern from
        #   the Valuation Control number autogenerator in the
        #   UI. The pattern is:
        #
        # - VC (customizable via the `prefix` parameter)
        # - 4-digit year (for rows with no date, the value given for
        #   `nodateval` will be inserted here)
        # - . (`preincrementsegment` param)
        # - autoincrementing digit
        #
        # ## ASSUMPTIONS OF THIS TRANSFORM
        #
        # - You will have already reduced the output to one row per valuation
        #   control to be created in CollectionSpace
        # - You will have used {DateValue::ForceDayPrecision} or some other
        #   method to create a field containing only blank values and valid
        #   ISO 8601 dates to be mapped to the unstructured date `valuedate`
        #   field in CollectionSpace
        #
        # ## SORTING, or, how the end digit gets incremented within a year
        #
        # See {IdGenerator::YearBasedIncrementing} for sorting details.
        # @example With default sorter
        #   # Used in pipeline as:
        #   # transform Cspace::Valuationcontrolrefnumber,
        #   #   datefield: :d,
        #   #   target: :tada
        #   xform = Cspace::Valuationcontrolrefnumber.new(
        #     datefield: :d,
        #     target: :tada
        #   )
        #   input = [
        #     {d: "2007-12-13", i: "a"},
        #     {d: "2000-05-23", i: "z"},
        #     {d: "2000-01-01", i: "c"},
        #     {d: "", i: "q"},
        #     {d: "2000-05-23", i: "g"},
        #     {d: "2007-10-31", i: "f"},
        #     {d: "2000-12-14", i: "h"},
        #     {d: "2000-05-23", i: "d"},
        #     {d: nil, i: "y"},
        #     {d: "2017-02-04", i: "x"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {d: "2007-10-31", i: "f", tada: "VC2007.1"},
        #     {d: "2007-12-13", i: "a", tada: "VC2007.2"},
        #     {d: "2000-01-01", i: "c", tada: "VC2000.1"},
        #     {d: "2000-05-23", i: "z", tada: "VC2000.2"},
        #     {d: "2000-05-23", i: "g", tada: "VC2000.3"},
        #     {d: "2000-05-23", i: "d", tada: "VC2000.4"},
        #     {d: "2000-12-14", i: "h", tada: "VC2000.5"},
        #     {d: "", i: "q", tada: "VC0000.1"},
        #     {d: nil, i: "y", tada: "VC0000.2"},
        #     {d: "2017-02-04", i: "x", tada: "VC2017.1"}
        #   ]
        #   expect(result).to eq(expected)
        class Valuationcontrolrefnumber
          # @param datefield [Symbol] field containing valid ISO 8601 dates and
          #   blank values only
          # @param target [Symbol] field in which to write the generated value
          # @param prefix [String] initial segment of generated value
          # @param preincrementsegment [String] optional segment of number
          #   after the year or `nodateval` and before the incrementing segment
          # @param nodateval [String] value inserted instead of the year, if
          #   `datefield` is blank
          # @param sorter [Lambda] taking `rows` and `datefield` args,
          #   and returning sorted rows
          def initialize(datefield:,
            prefix: "VC",
            nodateval: "0000",
            preincrementsegment: ".",
            target: :valuationcontrolrefnumber,
            sorter: nil)
            @generator = IdGenerator::YearBasedIncrementing.new(
              datefield: datefield,
              prefix: prefix,
              nodateval: nodateval,
              preincrementsegment: preincrementsegment,
              target: target,
              sorter: sorter
            )
          end

          def process(row)
            generator.process(row)
          end

          def close
            generator.finalized_rows
              .each { |row| yield row }
          end

          private

          attr_reader :generator
        end
      end
    end
  end
end
