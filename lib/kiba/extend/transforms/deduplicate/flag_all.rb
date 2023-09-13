# frozen_string_literal: true

# rubocop:todo Layout/LineLength

module Kiba
  module Extend
    module Transforms
      module Deduplicate
        # @since 2.9.0
        #
        # Adds a field (specified as `in_field`) containing 'y' or 'n', indicating whether value of `on_field`
        #   is a duplicate
        #
        # In contrast with {Deduplicate::Flag}, where the first instance of a value in `on_field` is always
        #   marked `n`, with {Deduplicate::FlagAll}, **all rows containing a duplicate value in `on_field` are
        #   marked `y`**.
        #
        # Input table:
        #
        # ~~~
        # | foo | bar | combined  |
        # |-----------------------|
        # | a   | b   | a b       |
        # | c   | d   | c d       |
        # | c   | e   | c e       |
        # | c   | d   | c d       |
        # ~~~
        #
        # Used in pipeline as:
        #
        # ~~~
        #   @deduper = {}
        #   transform Deduplicate::FlagAll, on_field: :combined, in_field: :duplicate
        # ~~~
        #
        # Results in:
        #
        # ~~~
        # | foo | bar | combined | duplicate |
        # |----------------------------------|
        # | a   | b   | a b      | n         |
        # | c   | d   | c d      | y         |
        # | c   | e   | c e      | n         |
        # | c   | d   | c d      | y         |
        # ~~~
        #
        class FlagAll
          # @param on_field [Symbol] Field on which to deduplicate
          # @param in_field [Symbol] New field in which to add 'y' or 'n'
          # @param explicit_no [Boolean] if false, `in_field` value for non-duplicate is left blank
          #   use this transform
          def initialize(on_field:, in_field:, explicit_no: true)
            @on = on_field
            @in_field = in_field
            @deduper = {}
            @no_val = explicit_no ? "n" : ""
            @rows = []
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            val = row[on]
            deduper.key?(val) ? deduper[val] += 1 : deduper[val] = 1
            rows << row
            nil
          end

          def close
            @rows.each do |row|
              val = row[on]
              row[in_field] = (deduper[val] > 1) ? "y" : no_val
              yield row
            end
          end

          private

          attr_reader :on, :in_field, :deduper, :no_val, :rows
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
