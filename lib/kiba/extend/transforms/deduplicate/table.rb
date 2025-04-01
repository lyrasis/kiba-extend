# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Deduplicate
        # Given a field on which to deduplicate, removes duplicate
        #   rows from table
        #
        # Keeps the row with the first instance of the value in the
        #   deduplicating field
        #
        # Tip: Use
        #   {Kiba::Extend::Transforms::CombineValues::FromFieldsWithDelimiter}
        #   or {Kiba::Extend::Transforms::CombineValues::FullRecord}
        #   to create a combined field on which to deduplicate
        #
        # @note This transform runs in memory, so for very large
        #   sources, it may take a long time or fail. In this case,
        #   use a combination of {Flag} and
        #   {Kiba::Extend::Transforms::FilterRows::FieldEqualTo}
        #
        # Input table:
        #
        # ~~~
        # | foo | bar | baz |  combined |
        # |-----------------------------|
        # | a   | b   | f   | a b       |
        # | c   | d   | g   | c d       |
        # | c   | e   | h   | c e       |
        # | c   | d   | i   | c d       |
        # | c   | d   | j   | c d       |
        # ~~~
        #
        # Used in pipeline as:
        #
        # ~~~
        # transform Deduplicate::Table, field: :combined, delete_field: true
        # ~~~
        #
        # Results in:
        #
        # ~~~
        # | foo | bar | baz |
        # |-----------------|
        # | a   | b   | f   |
        # | c   | d   | g   |
        # | c   | e   | h   |
        # ~~~
        #
        # Used in pipeline as:
        #
        # ~~~
        # transform Deduplicate::Table, field: :combined, delete_field: true,
        #   example_source_field: :baz, max_examples: 2,
        #   example_target_field: :ex, example_delim: ";"
        # ~~~
        #
        # Results in:
        #
        # ~~~
        # | foo | bar | baz | ex |
        # |-----------------|----|
        # | a   | b   | f   | f  |
        # | c   | d   | g   | g;i|
        # | c   | e   | h   | h  |
        # ~~~
        #
        #
        # Used in pipeline as:
        #
        # ~~~
        # transform Deduplicate::Table, field: :combined, delete_field: true,
        #   example_source_field: :baz, max_examples: 2,
        #   example_target_field: :ex, example_delim: ";", include_occs: true
        # ~~~
        #
        # Results in:
        #
        # ~~~
        # | foo | bar | baz | ex | occurrences |
        # |-----------------|----|-------------|
        # | a   | b   | f   | f  | 1           |
        # | c   | d   | g   | g;i| 3           |
        # | c   | e   | h   | h  | 1           |
        # ~~~
        #
        # @since 2.2.0
        class Table
          # @param field [Symbol] name of field on which to deduplicate
          # @param delete_field [Boolean] whether to delete the deduplication
          #   field after doing deduplication
          # @param example_source_field [nil, Symbol] field containing values to
          #   be compiled as examples
          # @param max_examples [Integer] maximum number of example values to
          #   return
          # @param example_target_field [Symbol] name of field in which to
          #   report example values
          # @param example_delim [String] used to join multiple example values
          # @param include_occs [Boolean] whether to report number of
          #   occurrences of each field value being deduplicated on
          # @param occs_target_field [Symbol] name of field in which to report
          #   occurrences
          def initialize(field:, delete_field: false, example_source_field: nil,
            max_examples: 10, example_target_field: :examples,
            example_delim: Kiba::Extend.delim,
            include_occs: false, occs_target_field: :occurrences)
            @field = field
            @deduper = {}
            @delete = delete_field
            @example = example_source_field
            @max_examples = max_examples
            @ex_target = example_target_field
            @delim = example_delim
            @occs = include_occs
            @occ_target = occs_target_field
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            field_val = row.fetch(field, nil)
            return if field_val.blank?

            get_row(field_val, row)
            get_occ(field_val, row) if occs
            get_example(field_val, row) if example
            nil
          end

          def close
            deduper.values.each do |hash|
              row = hash[:row]
              add_example_field(row, hash) if example
              row[occ_target] = hash[:occs] if occs
              row.delete(field) if delete
              yield row
            end
          end

          private

          attr_reader :field, :deduper, :delete, :example, :max_examples,
            :ex_target, :delim, :occs, :occ_target

          def get_row(field_val, row)
            return if deduper.key?(field_val)

            hash = {row: row}
            hash[:examples] = [] if example
            hash[:occs] = 0 if occs
            deduper[field_val] = hash
          end

          def get_occ(field_val, row) = deduper[field_val][:occs] += 1

          def get_example(field_val, row)
            return if deduper[field_val][:examples].length == max_examples

            deduper[field_val][:examples] << row[example]
          end

          def add_example_field(row, hash)
            row[ex_target] = hash[:examples].join(delim)
          end
        end
      end
    end
  end
end
