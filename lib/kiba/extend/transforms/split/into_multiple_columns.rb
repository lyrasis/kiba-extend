# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Split
        # Splits field into multiple fields, based on sep
        # rubocop:todo Layout/LineLength
        # New columns use the original field name, and add number to end (:field0, :field1, etc)
        # rubocop:enable Layout/LineLength
        #
        # # Example 1
        #
        # Input table:
        #
        # ```
        # | summary    |
        # |------------|
        # | a:b        |
        # | c          |
        # | :d         |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform Split::IntoMultipleColumns, field: :summary, sep: ':', max_segments: 2
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Results in:
        #
        # ```
        # | summary0 | summary1   |
        # |-----------------------|
        # | a        | b          |
        # | c        | nil        |
        # |          | d          |
        # ```
        #
        # # Example 2
        #
        # Input table:
        #
        # ```
        # | summary    |
        # |------------|
        # | a:b:c:d:e  |
        # | f:g        |
        # |            |
        # | nil        |
        # ```
        # Used in pipeline as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform Split::IntoMultipleColumns, field: :summary, sep: ':', max_segments: 3,
        # rubocop:enable Layout/LineLength
        #   collapse_on: :left, warnfield: :warnme
        # ```
        #
        # Results in:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # | summary0 | summary1 | summary2 | warnme                                                |
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # |----------------------------------------------------------------------------------------|
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # | a:b:c    | d        | e        | max_segments less than total number of split segments |
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # | f        | g        | nil      | nil                                                   |
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # |          | nil      | nil      | nil                                                   |
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # | nil      | nil      | nil      | nil                                                   |
        # rubocop:enable Layout/LineLength
        # ```
        # Used in pipeline as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform Split::IntoMultipleColumns, field: :summary, sep: ':', max_segments: 3,
        # rubocop:enable Layout/LineLength
        #   collapse_on: :right
        # ```
        #
        # Results in:
        #
        # ```
        # | summary0 | summary1 | summary2 |
        # |--------------------------------|
        # | a        | b        | c:d:e    |
        # | f        | g        | nil      |
        # |          | nil      | nil      |
        # | nil      | nil      | nil      |
        # ```
        class IntoMultipleColumns
          # @param field [Symbol] Name of field to split
          # @param sep [String] Character(s) on which to split the field value
          # rubocop:todo Layout/LineLength
          # @param delete_source [Boolean] Whether to delete `field` after splitting it into new columns
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param max_segments [Integer] Specification of the maximum number of segments to split
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   `field` value into (i.e. max number of columns to create from this one column).
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param collapse_on [:right, :left] Which end of the split array to join remaining split values
          # rubocop:enable Layout/LineLength
          #   if there are more than max_segments
          # rubocop:todo Layout/LineLength
          # @param warnfield [Symbol] Name of field in which to put any warning/error(s) for a row
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @note Since 2.0.0, the `max_segments` parameter is required. This is due to the row-by-row way
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   in which Kiba processes data. When processing one row that would be split into 2 columns,
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   the processor has no way of knowing that another row in the source should be split into 10
          # rubocop:enable Layout/LineLength
          #   columns and thus it creates rows with different numbers of fields.
          # rubocop:disable Metrics/ParameterLists
          # rubocop:todo Layout/LineLength
          def initialize(field:, sep:, max_segments:, delete_source: true, collapse_on: :right,
            # rubocop:enable Layout/LineLength
            warnfield: nil)
            @field = field
            @sep = sep
            @del = delete_source
            @max = max_segments
            @collapser = method("process_#{collapse_on}_collapse")
            @warn = !warnfield.blank?
            @warnfield = warnfield || :warning
            @warnvalue = "max_segments less than total number of split segments"
          end
          # rubocop:enable Metrics/ParameterLists

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
            "#{field}0".to_sym
          end

          def last_field
            "#{field}#{max - 1}".to_sym
          end

          def new_fields
            (0..(max - 1)).entries.map { |entry| "#{field}#{entry}".to_sym }
          end

          def process_left_collapse(valsplit, row)
            add_warning(row)

            ind = max - 1
            to_iterate(valsplit).times do
              row["#{field}#{ind}".to_sym] = valsplit.pop
              ind -= 1
            end
            row[first_field] = valsplit.join(sep)
          end

          def process_right_collapse(valsplit, row)
            add_warning(row)

            ind = 0
            to_iterate(valsplit).times do
              row["#{field}#{ind}".to_sym] = valsplit.shift
              ind += 1
            end
            row[last_field] = valsplit.join(sep)
          end

          def process_splits(valsplit, row)
            valsplit.each_with_index { |val, i|
              row["#{field}#{i}".to_sym] = val
            }
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
