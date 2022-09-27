# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Deduplicate
        # Adds a field (`in_field`) containing 'y' or 'n', indicating whether value of `on_field` is a duplicate
        #
        # The first instance of a value in `on_field` is always marked `n`. Subsequent rows containing the same
        #   value will be marked 'y'
        #
        # Use this transform if you need to retain/report on what will be treated as a duplicate. Use
        #   {Kiba::Extend::Transforms::FilterRows::FieldEqualTo} to extract only the duplicate rows and/or to
        #   keep only the non-duplicate rows.
        #
        # Use {FlagAll} if you need all rows containing duplicate values flagged `y`.
        #
        # To delete duplicates all in one step, use {Kiba::Extend::Transforms::Deduplicate::Table}
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
        #   transform Deduplicate::Flag, on_field: :combined, in_field: :duplicate, using: @deduper
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
          # @param using [Hash] An empty Hash, set as an instance variable in your job definition before you
          # @param explicit_no [Boolean] if false, `in_field` value for non-duplicate is left blank
          #   use this transform
          def initialize(on_field:, in_field:, using:, explicit_no: true)
            @on = on_field
            @in_field = in_field
            @using = using
            raise NoUsingValueError, "#{self.class.name} `using` hash does not exist" unless @using
            @no_val = explicit_no ? 'n' : ''
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            val = row.fetch(on)
            if using.key?(val)
              row[in_field] = 'y'
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
