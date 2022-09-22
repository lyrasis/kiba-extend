# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Deduplicate
        # Given a field on which to deduplicate, removes duplicate rows from table
        #
        # Keeps the row with the first instance of the value in the deduplicating field
        #
        # Tip: Use {Kiba::Extend::Transforms::CombineValues::FromFieldsWithDelimiter} or
        #   {Kiba::Extend::Transforms::CombineValues::FullRecord} to create a combined field on which to deduplicate
        #
        # @note This transform runs in memory, so for very large sources, it may take a long time or fail. In this
        #   case, use a combination of {Flag} and {Kiba::Extend::Transforms::FilterRows::FieldEqualTo}
        #
        # Input table:
        #
        # ```
        # | foo | bar | baz |  combined |
        # |-----------------------------|
        # | a   | b   | f   | a b       |
        # | c   | d   | g   | c d       |
        # | c   | e   | h   | c e       |
        # | c   | d   | i   | c d       |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Deduplicate::Table, field: :combined, delete_field: true
        # ```
        #
        # Results in:
        #
        # ```
        # | foo | bar | baz |
        # |-----------------|
        # | a   | b   | f   |
        # | c   | d   | g   |
        # | c   | e   | h   |
        # ```
        #
        # @since 2.2.0
        class Table
          # @param field [Symbol] name of field on which to deduplicate
          # @param delete_field [Boolean] whether to delete the deduplication field after doing deduplication
          def initialize(field:, delete_field: false)
            @field = field
            @deduper = {}
            @delete = delete_field
          end
          
          # @param row [Hash{ Symbol => String }]
          def process(row)
            field_val = row.fetch(@field, nil)
            return if field_val.blank?
            return if @deduper.key?(field_val)

            @deduper[field_val] = row
            nil
          end

          def close
            @deduper.values.each do |row|
              row.delete(@field) if @delete
              yield row
            end
          end
        end
      end
    end
  end
end
