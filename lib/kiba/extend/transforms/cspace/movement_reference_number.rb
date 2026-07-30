# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Cspace
        # Generates typical pattern of movementReferenceNumbers based on
        #   year in location date, where available. For each year, the
        #   procedure data is sorted by the full date value, and the
        #   reference number value is incremented.
        #
        # The typical number pattern used is the location record pattern from
        #   the number autogenerator in Location/Movement/Inventory (LMI) the
        #   UI. The pattern is:
        #
        # - LOC (customizable via the `prefix` parameter)
        # - 4-digit year (for rows with no date, the value given for
        #   `nodateval` will be inserted here)
        # - .1 (this is one of those meaningless id number segments that never
        #   gets incremented, but clients like to have it there to match the
        #   default autogenerator, so here we are... customize this if desired
        #   via the `initialsegment` param)
        # - .
        # - autoincrementing digit
        #
        # ## ASSUMPTIONS OF THIS TRANSFORM
        #
        # - You will have already reduced the output to one row per LMI to be
        #   created in CollectionSpace
        # - You will have used {DateValue::ForceDayPrecision} or some other
        #   method to create a field containing only blank values and valid
        #   ISO 8601 dates to be mapped to the unstructured date `locationdate`
        #   field in CollectionSpace
        #
        # ## SORTING, or, how the end digit gets incremented within a year
        #
        # During the first pass over the data, we populate `holder` hash. Keys
        #   are the years extracted from the `datefield` values in all rows.
        #   Values are the rows from whom that year was extracted.
        #
        # In the final pass, a sorter is applied to the Array of rows for each
        #   year key.
        #
        # The default sorter:
        #
        # - parses the `datefield` value to create a sortable Ruby Date if a
        #   value is present; uses `0001-01-01` if not
        # - sorts by this Ruby Date
        # - if a number of rows have the same date, they'll be in the same order
        #   as they appear in the data before this transform is applied
        #
        # If your data contains full time stamps or some other sequential value
        #   you would like to use to sort, you can pass a custom `sorter` Lamda.
        #   This Lambda should take two positional arguments. The transform
        #   passes the Array of rows for the year key as the first argument,
        #   and the `datefield` attr value as the second. See the custom sorter
        #   example for how you can indicate the `datefield` attr won't be used.
        #   It should return the Array of rows, sorted as desired.
        # @example With default sorter
        #   # Used in pipeline as:
        #   # transform Cspace::MovementReferenceNumber,
        #   #   datefield: :d,
        #   #   target: :tada
        #   xform = Cspace::MovementReferenceNumber.new(
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
        #     {d: "2007-10-31", i: "f", tada: "LOC2007.1.1"},
        #     {d: "2007-12-13", i: "a", tada: "LOC2007.1.2"},
        #     {d: "2000-01-01", i: "c", tada: "LOC2000.1.1"},
        #     {d: "2000-05-23", i: "z", tada: "LOC2000.1.2"},
        #     {d: "2000-05-23", i: "g", tada: "LOC2000.1.3"},
        #     {d: "2000-05-23", i: "d", tada: "LOC2000.1.4"},
        #     {d: "2000-12-14", i: "h", tada: "LOC2000.1.5"},
        #     {d: "", i: "q", tada: "LOC0000.1.1"},
        #     {d: nil, i: "y", tada: "LOC0000.1.2"},
        #     {d: "2017-02-04", i: "x", tada: "LOC2017.1.1"}
        #   ]
        #   expect(result).to eq(expected)
        # @example With custom sorter
        #   # Used in pipeline as:
        #   # transform Cspace::MovementReferenceNumber,
        #   #   datefield: :d,
        #   #   target: :tada,
        #   #   sorter: ->(r, _na) do
        #   #     r.sort_by { |row| row[:i] }
        #   #   end
        #   xform = Cspace::MovementReferenceNumber.new(
        #     datefield: :d,
        #     target: :tada,
        #     sorter: ->(r, _na) do
        #       r.sort_by { |row| row[:i] }
        #     end
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
        #     {d: "2007-12-13", i: "a", tada: "LOC2007.1.1"},
        #     {d: "2007-10-31", i: "f", tada: "LOC2007.1.2"},
        #     {d: "2000-01-01", i: "c", tada: "LOC2000.1.1"},
        #     {d: "2000-05-23", i: "d", tada: "LOC2000.1.2"},
        #     {d: "2000-05-23", i: "g", tada: "LOC2000.1.3"},
        #     {d: "2000-12-14", i: "h", tada: "LOC2000.1.4"},
        #     {d: "2000-05-23", i: "z", tada: "LOC2000.1.5"},
        #     {d: "", i: "q", tada: "LOC0000.1.1"},
        #     {d: nil, i: "y", tada: "LOC0000.1.2"},
        #     {d: "2017-02-04", i: "x", tada: "LOC2017.1.1"}
        #   ]
        #   expect(result).to eq(expected)
        class MovementReferenceNumber
          # This sorter is used if no custom sorter is passed in when
          #   initializing the transform
          DEFAULT_SORTER = ->(rows, datefield) do
            rows.sort_by do |row|
              dateval = row[datefield]
              dateval.blank? ? Date.new(1, 1, 1) : Date.parse(dateval)
            end
          end

          # @param datefield [Symbol] field containing valid ISO 8601 dates and
          #   blank values only
          # @param prefix [String] initial segment of generated value
          # @param nodateval [String] value inserted instead of the year, if
          #   `datefield` is blank
          # @param initialsegment [String] the first segment of number after the
          #   year or `nodateval`
          # @param target [Symbol] field in which to write the generated value
          # @param sorter [Lambda] taking `rows` and `datefield` args,
          #   and returning sorted rows
          def initialize(datefield:,
            prefix: "LOC",
            nodateval: "0000",
            initialsegment: ".1",
            target: :movementreferencenumber,
            sorter: DEFAULT_SORTER)
            @datefield = datefield
            @prefix = prefix
            @nodateval = nodateval
            @initialsegment = initialsegment
            @target = target
            @nodatesortval = nodatesortval
            @sorter = sorter
            @holder = {}
          end

          def process(row)
            dateval = row[datefield]
            year = dateval.blank? ? nodateval : dateval[0..3]
            populate_holder(row, year)

            nil
          end

          def close
            holder.map { |year, data| generate_for_year(year, data) }
              .flatten
              .each { |row| yield row }
          end

          private

          attr_reader :datefield, :prefix, :nodateval, :initialsegment,
            :target, :nodatesortval, :sorter, :holder

          def parse_date(dateval)
            return "" if dateval.blank?

            Date.parse(dateval)
          rescue
            ""
          end

          def populate_holder(row, year)
            holder[year] = [] unless holder.key?(year)
            holder[year] << row
          end

          def generate_for_year(year, data)
            base = "#{prefix}#{year}.1."
            counter = 0
            sorter.call(data, datefield)
              .map do |row|
                counter += 1
                row[target] = "#{base}#{counter}"

                row
              end
          end
        end
      end
    end
  end
end
