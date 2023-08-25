# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Deduplicate
        # rubocop:todo Layout/LineLength
        # Adds a field (`in_field`) containing 'y' or 'n', indicating whether value of `on_field` is a duplicate
        # rubocop:enable Layout/LineLength
        #
        # rubocop:todo Layout/LineLength
        # The first instance of a value in `on_field` is always marked `n`. Subsequent rows containing the same
        # rubocop:enable Layout/LineLength
        #   value will be marked 'y'
        #
        # rubocop:todo Layout/LineLength
        # Use this transform if you need to retain/report on what will be treated as a duplicate. Use
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {Kiba::Extend::Transforms::FilterRows::FieldEqualTo} to extract only the duplicate rows and/or to
        # rubocop:enable Layout/LineLength
        #   keep only the non-duplicate rows.
        #
        # rubocop:todo Layout/LineLength
        # Use {FlagAll} if you need all rows containing duplicate values flagged `y`.
        # rubocop:enable Layout/LineLength
        #
        # rubocop:todo Layout/LineLength
        # To delete duplicates all in one step, use {Kiba::Extend::Transforms::Deduplicate::Table}
        # rubocop:enable Layout/LineLength
        #
        # Input table:
        #
        # ```
        # | foo | bar | combined  |
        # |-----------------------|
        # | a   | b   | a b       |
        # | c   | d   | c d       |
        # | c   | e   | c e       |
        # | c   | d   | c d       |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #   @deduper = {}
        # rubocop:todo Layout/LineLength
        #   transform Deduplicate::Flag, on_field: :combined, in_field: :duplicate, using: @deduper
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Results in:
        #
        # ```
        # | foo | bar | combined | duplicate |
        # |----------------------------------|
        # | a   | b   | a b      | n         |
        # | c   | d   | c d      | n         |
        # | c   | e   | c e      | n         |
        # | c   | d   | c d      | y         |
        # ```
        #
        class Flag
          class NoUsingValueError < Kiba::Extend::Error; end

          # @param on_field [Symbol] Field on which to deduplicate
          # @param in_field [Symbol] New field in which to add 'y' or 'n'
          # rubocop:todo Layout/LineLength
          # @param using [Hash] An empty Hash, set as an instance variable in your job definition before you
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param explicit_no [Boolean] if false, `in_field` value for non-duplicate is left blank
          # rubocop:enable Layout/LineLength
          #   use this transform
          def initialize(on_field:, in_field:, using:, explicit_no: true)
            @on = on_field
            @in_field = in_field
            @using = using
            unless @using
              raise NoUsingValueError,
                "#{self.class.name} `using` hash does not exist"
            end
            @no_val = explicit_no ? "n" : ""
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            val = row.fetch(on)
            if using.key?(val)
              row[in_field] = "y"
            else
              using[val] = nil
              row[in_field] = no_val
            end
            row
          end

          private

          attr_reader :on, :in_field, :using, :no_val
        end
      end
    end
  end
end
