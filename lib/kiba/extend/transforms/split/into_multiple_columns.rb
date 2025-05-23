# frozen_string_literal: true

# rubocop:todo Layout/LineLength

module Kiba
  module Extend
    module Transforms
      module Split
        # Splits field into multiple fields, based on sep
        # New columns use the original field name, and add number to end (:field0, :field1, etc)
        #
        # # Example 1
        #
        # Input table:
        #
        # ~~~
        # | summary    |
        # |------------|
        # | a:b        |
        # | c          |
        # | :d         |
        # ~~~
        #
        # Used in pipeline as:
        #
        # ~~~
        # transform Split::IntoMultipleColumns, field: :summary, sep: ':', max_segments: 2
        # ~~~
        #
        # Results in:
        #
        # ~~~
        # | summary0 | summary1   |
        # |-----------------------|
        # | a        | b          |
        # | c        | nil        |
        # |          | d          |
        # ~~~
        #
        # # Example 2
        #
        # Input table:
        #
        # ~~~
        # | summary    |
        # |------------|
        # | a:b:c:d:e  |
        # | f:g        |
        # |            |
        # | nil        |
        # ~~~
        # Used in pipeline as:
        #
        # ~~~
        # transform Split::IntoMultipleColumns, field: :summary, sep: ':', max_segments: 3,
        #   collapse_on: :left, warnfield: :warnme
        # ~~~
        #
        # Results in:
        #
        # ~~~
        # | summary0 | summary1 | summary2 | warnme                                                |
        # |----------------------------------------------------------------------------------------|
        # | a:b:c    | d        | e        | max_segments less than total number of split segments |
        # | f        | g        | nil      | nil                                                   |
        # |          | nil      | nil      | nil                                                   |
        # | nil      | nil      | nil      | nil                                                   |
        # ~~~
        # Used in pipeline as:
        #
        # ~~~
        # transform Split::IntoMultipleColumns, field: :summary, sep: ':', max_segments: 3,
        #   collapse_on: :right
        # ~~~
        #
        # Results in:
        #
        # ~~~
        # | summary0 | summary1 | summary2 |
        # |--------------------------------|
        # | a        | b        | c:d:e    |
        # | f        | g        | nil      |
        # |          | nil      | nil      |
        # | nil      | nil      | nil      |
        # ~~~
        class IntoMultipleColumns
          # @param field [Symbol] Name of field to split
          # @param sep [String] Character(s) on which to split the field value
          # @param delete_source [Boolean] Whether to delete `field` after splitting it into new columns
          # @param max_segments [Integer] Specification of the maximum number of segments to split
          #   `field` value into (i.e. max number of columns to create from this one column).
          # @param collapse_on [:right, :left] Which end of the split array to join remaining split values
          #   if there are more than max_segments
          # @param warnfield [Symbol] Name of field in which to put any warning/error(s) for a row
          # @note Since 2.0.0, the `max_segments` parameter is required. This is due to the row-by-row way
          #   in which Kiba processes data. When processing one row that would be split into 2 columns,
          #   the processor has no way of knowing that another row in the source should be split into 10
          #   columns and thus it creates rows with different numbers of fields.
          def initialize(field:, sep:, max_segments:, delete_source: true, collapse_on: :right,
            warnfield: nil)
            @field = field
            @sep = sep
            @del = delete_source
            @max = max_segments
            @collapser = method(:"process_#{collapse_on}_collapse")
            @warn = !warnfield.blank?
            @warnfield = warnfield || :warning
            @warnvalue = "max_segments less than total number of split segments"
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            add_new_fields(row)
            do_split(row)
            clean_up_fields(row)
            row
          end

          private

          attr_reader :field, :sep, :del, :max, :collapser, :warn, :warnfield,
            :warnvalue

          def add_new_fields(row)
            new_fields.each { |field| row[field] = nil }
            row[warnfield] = nil
          end

          def add_warning(row)
            row[warnfield] = warnvalue
          end

          def clean_up_fields(row)
            row.delete(field) if del
            row.delete(warnfield) unless warn
            strip_new_fields(row)
          end

          def do_split(row)
            val = row[field]
            return if val.blank?

            valsplit = val.split(sep)

            exceeds_max?(valsplit) ? collapser.call(valsplit,
              row) : process_splits(valsplit, row)
          end

          def exceeds_max?(valsplit)
            valsplit.length > max
          end

          def first_field
            :"#{field}0"
          end

          def last_field
            :"#{field}#{max - 1}"
          end

          def new_fields
            (0..(max - 1)).entries.map { |entry| :"#{field}#{entry}" }
          end

          def process_left_collapse(valsplit, row)
            add_warning(row)

            ind = max - 1
            to_iterate(valsplit).times do
              row[:"#{field}#{ind}"] = valsplit.pop
              ind -= 1
            end
            row[first_field] = valsplit.join(sep)
          end

          def process_right_collapse(valsplit, row)
            add_warning(row)

            ind = 0
            to_iterate(valsplit).times do
              row[:"#{field}#{ind}"] = valsplit.shift
              ind += 1
            end
            row[last_field] = valsplit.join(sep)
          end

          def process_splits(valsplit, row)
            valsplit.each_with_index do |val, i|
              row[:"#{field}#{i}"] = val
            end
          end

          def strip_new_fields(row)
            new_fields.each do |field|
              val = row[field]
              next if val.blank?

              row[field] = val.strip
            end
          end

          def to_collapse(valsplit)
            (valsplit.length - max) + 1
          end

          def to_iterate(valsplit)
            valsplit.length - to_collapse(valsplit)
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
