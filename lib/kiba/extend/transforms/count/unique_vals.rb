# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Count
        # Write count of unique values in field to the given target field.
        #   Optionally, group the values under another field for counting
        # @since 5.1.0
        # @note This transform runs in memory, so for very large
        #   sources, it may take a long time or fail.
        # @example Ungrouped, case sensitive, do not count blanks
        #   # Used in pipeline as:
        #   # transform Count::UniqueVals,
        #   #   value_field: :foo,
        #   #   target: :fooct
        #   xform = Count::UniqueVals.new(
        #     value_field: :foo,
        #     target: :fooct
        #   )
        #   input = [
        #     {foo: "a"},
        #     {foo: "A"},
        #     {foo: "c"},
        #     {foo: "C"},
        #     {foo: "c"},
        #     {foo: "c"},
        #     {foo: nil},
        #     {foo: ""}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {foo: "a", fooct: 4},
        #     {foo: "A", fooct: 4},
        #     {foo: "c", fooct: 4},
        #     {foo: "C", fooct: 4},
        #     {foo: "c", fooct: 4},
        #     {foo: "c", fooct: 4},
        #     {foo: nil, fooct: 4},
        #     {foo: "", fooct: 4}
        #   ]
        #   expect(result).to eq(expected)
        # @example Ungrouped, case sensitive, count blanks
        #   # Used in pipeline as:
        #   # transform Count::UniqueVals,
        #   #   value_field: :foo,
        #   #   target: :fooct,
        #   #   count_blank: true
        #   xform = Count::UniqueVals.new(
        #     value_field: :foo,
        #     target: :fooct,
        #     count_blank: true
        #   )
        #   input = [
        #     {foo: "a"},
        #     {foo: "A"},
        #     {foo: "c"},
        #     {foo: "C"},
        #     {foo: "c"},
        #     {foo: "c"},
        #     {foo: nil},
        #     {foo: ""},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {foo: "a", fooct: 5},
        #     {foo: "A", fooct: 5},
        #     {foo: "c", fooct: 5},
        #     {foo: "C", fooct: 5},
        #     {foo: "c", fooct: 5},
        #     {foo: "c", fooct: 5},
        #     {foo: nil, fooct: 5},
        #     {foo: "", fooct: 5}
        #   ]
        #   expect(result).to eq(expected)
        # @example Ungrouped, case insensitive
        #   # Used in pipeline as:
        #   # transform Count::UniqueVals,
        #   #   value_field: :foo,
        #   #   target: :fooct
        #   #   casesensitive: false
        #   xform = Count::UniqueVals.new(
        #     value_field: :foo,
        #     target: :fooct,
        #     casesensitive: false
        #   )
        #   input = [
        #     {foo: "a"},
        #     {foo: "A"},
        #     {foo: "c"},
        #     {foo: "C"},
        #     {foo: "c"},
        #     {foo: "c"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {foo: "a", fooct: 2},
        #     {foo: "A", fooct: 2},
        #     {foo: "c", fooct: 2},
        #     {foo: "C", fooct: 2},
        #     {foo: "c", fooct: 2},
        #     {foo: "c", fooct: 2}
        #   ]
        #   expect(result).to eq(expected)
        # @example Grouped, case sensitive, count blanks
        #   # Used in pipeline as:
        #   # transform Count::UniqueVals,
        #   #   value_field: :accdate,
        #   #   target: :datect,
        #   #   group_field: :accnum,
        #   #   count_blank: true
        #   xform = Count::UniqueVals.new(
        #     value_field: :accdate,
        #     target: :datect,
        #     group_field: :accnum,
        #     count_blank: true
        #   )
        #   input = [
        #     {accnum: "A1", accdate: "2025-09-01"},
        #     {accnum: "A1", accdate: ""},
        #     {accnum: "A1", accdate: "2025-09-01"},
        #     {accnum: "A2", accdate: "2025-09-05"},
        #     {accnum: "A2", accdate: "2025-09-05"},
        #     {accnum: "A2", accdate: "2025-07-30"},
        #     {accnum: "A3", accdate: "2025-09-09"},
        #     {accnum: "A3", accdate: "2025-09-09"},
        #     {accnum: "A3", accdate: "2025-09-09"},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {accnum: "A1", accdate: "2025-09-01", datect: 2},
        #     {accnum: "A1", accdate: "", datect: 2},
        #     {accnum: "A1", accdate: "2025-09-01", datect: 2},
        #     {accnum: "A2", accdate: "2025-09-05", datect: 2},
        #     {accnum: "A2", accdate: "2025-09-05", datect: 2},
        #     {accnum: "A2", accdate: "2025-07-30", datect: 2},
        #     {accnum: "A3", accdate: "2025-09-09", datect: 1},
        #     {accnum: "A3", accdate: "2025-09-09", datect: 1},
        #     {accnum: "A3", accdate: "2025-09-09", datect: 1},
        #   ]
        #   expect(result).to eq(expected)
        class UniqueVals
          # @param value_field [Symbol] field whose unique values will be
          #   counted
          # @param target [Symbol] field into which count will be written
          # @param group_field [nil, Symbol] field under which counts will be
          #   grouped
          # @param casesensitive [Boolean] whether case matters in identifying
          #   duplicates vs. unique values
          # @param count_blank [Boolean] whether to count blank values as values
          def initialize(value_field:, target:, group_field: nil,
            casesensitive: true, count_blank: false)
            @value_field = value_field
            @target = target
            @group_field = group_field
            @casesensitive = casesensitive
            @count_blank = count_blank
            @grouper = {}
            @rows = []
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            extract_for_count(row)
            rows << row
            nil
          end

          def close
            @ct = grouper.keys.length unless group_field
            rows.each { |row| yield add_count_to(row) }
          end

          private

          attr_reader :value_field, :target, :group_field, :casesensitive,
            :count_blank, :grouper, :rows

          def extract_for_count(row)
            val = row[value_field]
            return if val.blank? && !count_blank

            compare = get_compare_value(val)
            if group_field
              extract_grouped_for_count(row, compare)
            else
              grouper[compare] = nil
            end
          end

          def get_compare_value(val)
            return Kiba::Extend.nullvalue if val.blank?
            return val if casesensitive

            val.downcase
          end

          def extract_grouped_for_count(row, compare)
            groupval = row[group_field]
            grouper[groupval] = {} unless grouper.key?(groupval)
            grouper[groupval][compare] = nil
          end

          def add_count_to(row)
            if group_field
              groupval = row[group_field]
              row[target] = if groupval && grouper.key?(groupval)
                grouper[groupval].keys.length
              end
            else
              row[target] = @ct
            end
            row
          end
        end
      end
    end
  end
end
