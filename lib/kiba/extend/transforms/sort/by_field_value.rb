# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Sort
        # Returns all rows, sorted by the values of the given field.
        #
        #
        #
        # **Sort modes**
        #
        # **:smart**: Values consisting only of digits are converted to Integers
        #   for sort. Values consisting only of digits and a single "." are
        #   converted to Floats. Everything else is treated as a String.
        #
        # **:string**: All values treated as Strings
        #
        # @example With defaults
        #   # Used in pipeline as:
        #   # transform Sort::ByFieldValue, field: :id
        #   xform = Sort::ByFieldValue.new(field: :id)
        #   input = [
        #     {id: "40.75"},
        #     {id: "a"},
        #     {id: "41"},
        #     {id: "400"},
        #     {id: ""},
        #     {pid: "40"},
        #     {id: "40.5"},
        #     {id: nil},
        #     {id: "40_ex"},
        #     {id: "ex"},
        #     {id: "40"},
        #     {id: "ex ab"},
        #     {id: "a|b"},
        #     {id: "40|41"},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {id: "40"},
        #     {id: "40.5"},
        #     {id: "40.75"},
        #     {id: "41"},
        #     {id: "400"},
        #     {id: "40_ex"},
        #     {id: "40|41"},
        #     {id: "a"},
        #     {id: "a|b"},
        #     {id: "ex"},
        #     {id: "ex ab"},
        #     {id: ""},
        #     {pid: "40"},
        #     {id: nil},
        #   ]
        #   expect(result).to eq(expected)
        # @example With mode = :string and order = :desc
        #   # Used in pipeline as:
        #   # transform Sort::ByFieldValue,
        #   #   field: :id,
        #   #   mode: :string,
        #   #   order: :desc
        #   xform = Sort::ByFieldValue.new(field: :id, mode: :string,
        #     order: :desc)
        #   input = [
        #     {id: "40.75"},
        #     {id: "a"},
        #     {id: "41"},
        #     {id: "400"},
        #     {id: ""},
        #     {id: "40.5"},
        #     {id: nil},
        #     {id: "40_ex"},
        #     {id: "ex"},
        #     {id: "40"},
        #     {id: "ex ab"},
        #     {id: "a|b"},
        #     {id: "40|41"},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {id: "ex ab"},
        #     {id: "ex"},
        #     {id: "a|b"},
        #     {id: "a"},
        #     {id: "41"},
        #     {id: "40|41"},
        #     {id: "40_ex"},
        #     {id: "400"},
        #     {id: "40.75"},
        #     {id: "40.5"},
        #     {id: "40"},
        #     {id: ""},
        #     {id: nil},
        #   ]
        #   expect(result).to eq(expected)
        # @example With blanks = :first
        #   # Used in pipeline as:
        #   # transform Sort::ByFieldValue,
        #   #   field: :id,
        #   #   blanks: :first
        #   xform = Sort::ByFieldValue.new(field: :id, blanks: :first)
        #   input = [
        #     {id: "400"},
        #     {id: ""},
        #     {id: "a"},
        #     {id: nil},
        #     {id: "41"},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {id: ""},
        #     {id: nil},
        #     {id: "41"},
        #     {id: "400"},
        #     {id: "a"},
        #   ]
        #   expect(result).to eq(expected)
        # @example With delim
        #   # Used in pipeline as:
        #   # transform Sort::ByFieldValue,
        #   #   field: :id,
        #   #   delim: "|"
        #   xform = Sort::ByFieldValue.new(field: :id, delim: "|")
        #   input = [
        #     {id: "an"},
        #     {id: "400"},
        #     {id: "a|z"},
        #     {id: "40"},
        #     {id: "40|41"},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {id: "40"},
        #     {id: "40|41"},
        #     {id: "400"},
        #     {id: "a|z"},
        #     {id: "an"},
        #   ]
        #   expect(result).to eq(expected)
        #
        # @since 4.0.0
        class ByFieldValue
          # @param field [Symbol] Field whose values will be used for sort
          # @param blanks [:first, :last] Whether rows with blank values should
          #   be sorted first or last
          # @param delim [String, nil] if given, values will be split and
          #   only the first of multiple values will be used for sort. If not
          #   specified, the whole multivalue string will be used for sort
          # @param mode [:smart, :string]
          # @param order [:asc, :desc] of sortable rows. This does *not* change
          #   where blank values are placed
          def initialize(field:, blanks: :last, delim: nil, mode: :smart,
            order: :asc)
            @field = field
            @blanks = blanks
            @delim = delim
            @mode = mode
            @order = order
            @rows = {string: [], numeric: [], blank: []}
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            if row.key?(field)
              val = row[field]
              val.blank? ? rows[:blank] << row : sortable(row, val)
            else
              rows[:blank] << row
            end

            nil
          end

          def close
            rows[:blank].each { |row| yield row } if blanks == :first
            sorted.each { |entry| yield entry[1] }
            rows[:blank].each { |row| yield row } if blanks == :last
          end

          private

          attr_reader :field, :blanks, :delim, :mode, :order, :rows

          def sortable(row, val)
            sval = delim ? val.split(delim).first : val
            if mode == :smart
              convert(sval, row)
            else
              rows[:string] << [sval, row]
            end
          end

          def convert(val, row)
            if /^\d+$/.match?(val)
              rows[:numeric] << [val.to_i, row]
            elsif /^\d+\.\d+$/.match?(val)
              rows[:numeric] << [val.to_f, row]
            else
              rows[:string] << [val, row]
            end
          end

          def sorted
            rows[:string].sort_by! { |entry| entry[0] }
            rows[:numeric].sort_by! { |entry| entry[0] }
            result = rows[:numeric] + rows[:string]
            return result if order == :asc

            result.reverse
          end
        end
      end
    end
  end
end
