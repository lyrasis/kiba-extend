# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that split data
      module Split
        ::Split = Kiba::Extend::Transforms::Split
        # Splits field into multiple fields, based on sep
        # New columns use the original field name, and add number to end (:field0, :field1, etc)
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
        # transform Split::IntoMultipleColumns, field: :summary, sep: ':', max_segments: 2
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
        # transform Split::IntoMultipleColumns, field: :summary, sep: ':', max_segments: 3,
        #   collapse_on: :left, warnfield: :warnme
        # ```
        #
        # Results in:
        #
        # ```
        # | summary0 | summary1 | summary2 | warnme                                                |
        # |----------------------------------------------------------------------------------------|
        # | a:b:c    | d        | e        | max_segments less than total number of split segments |
        # | f        | g        | nil      | nil                                                   |
        # |          | nil      | nil      | nil                                                   |
        # | nil      | nil      | nil      | nil                                                   |
        # ```
        # Used in pipeline as:
        #
        # ```
        # transform Split::IntoMultipleColumns, field: :summary, sep: ':', max_segments: 3,
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
          # rubocop:disable Metrics/ParameterLists
          def initialize(field:, sep:, delete_source: true, max_segments:, collapse_on: :right,
                         warnfield: nil)
            @field = field
            @sep = sep
            @del = delete_source
            @max = max_segments
            @collapse_on = collapse_on
            @warn = !warnfield.blank?
            @warnfield = warnfield ||= :warning
            @new_fields = (0..(@max - 1)).entries.map { |entry| "#{field}#{entry}".to_sym }
          end
          # rubocop:enable Metrics/ParameterLists

          # @private
          def process(row)
            create_new_fields(row)
            val = row.fetch(@field, nil)
            if val.blank?
              row[@new_fields.first] = val unless val.nil?
              clean_up_fields(row)
              return row
            end

            valsplit = val.split(@sep).map(&:strip)

            if exceeds_max?(valsplit)
              row[@warnfield] = 'max_segments less than total number of split segments'
              method("process_#{@collapse_on}_collapse").call(valsplit, row)
            else
              process_splits(valsplit, row)
            end

            clean_up_fields(row)
            row
          end

          private

          def clean_up_fields(row)
            row.delete(@field) if @del
            row.delete(@warnfield) unless @warn
            row
          end

          def create_new_fields(row)
            @new_fields.each { |field| row[field] = nil }
            row[@warnfield] = nil
            row
          end

          def diff(valsplit)
            valsplit.size - @max
          end

          def exceeds_max?(valsplit)
            valsplit.size > @max
          end

          def process_exceeding(valsplit, row)
            if @collapse_on == :right
              process_right_split(valsplit, row)
            end
          end

          def process_right_collapse(valsplit, row)
            valsplit.slice!(0..(diff(valsplit) - 1)).each_with_index do |val, i|
              row["#{@field}#{i}".to_sym] = val
            end
            row["#{@field}#{@max - 1}".to_sym] = valsplit.join(@sep)
            row
          end

          def process_left_collapse(valsplit, row)
            dif = diff(valsplit)
            valsplit.slice!(dif * -1, dif).each_with_index do |val, i|
              row["#{@field}#{i + 1}".to_sym] = val
            end
            row["#{@field}0".to_sym] = valsplit.join(@sep)
            row
          end

          def process_splits(valsplit, row)
            valsplit.each_with_index { |val, i| row["#{@field}#{i}".to_sym] = val }
            row
          end
        end
      end
    end
  end
end
