# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module CombineValues
        ::CombineValues = Kiba::Extend::Transforms::CombineValues
        # Combine values from given fields into the target field.
        #
        # This is like the CONCATENATE function in many spreadsheets. The given `sep` value is used as a separator between the combined values.
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | col1 | col2 | col3 |
        # |------+------+------|
        # | a    | b    | c    |
        # | d    | e    | nil  |
        # | nil  | f    | g    |
        # | nil  | h    |      |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform CombineValues::FromFieldsWithDelimiter,
        #    sources: %i[col1 col3],
        #    target: :combined,
        #    sep: ' - ',
        #    delete_sources: false
        # ```
        #
        # Results in:
        #
        # ```
        # | col1 | col2 | col3 | combined |
        # |------+------+------+----------|
        # | a    | b    | c    | a - c    |
        # | d    | e    | nil  | d        |
        # | nil  | f    | g    | g        |
        # | nil  | h    |      | nil      |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform CombineValues::FromFieldsWithDelimiter,
        #    sources: %i[col1 col3],
        #    target: :col1,
        #    sep: ' - ',
        #    prepend_source_field_name: true
        # ```
        #
        # Results in:
        #
        # ```
        # | col2 | col1                 |
        # +------+----------------------|
        # | b    | col1: a - col3: c    |
        # | e    | col1: d              |
        # | f    | col3: g              |
        # | h    | nil                  |
        # ```
        class FromFieldsWithDelimiter
          # @param sources [Array<Symbol>] Fields whose values are to be combined
          # @param target [Symbol] Field into which the combined value will be written. May be one of the source fields
          # @param sep [String] Value inserted between combined field values
          # @param prepend_source_field_name [Boolean] Whether to insert the source field name before its value in the combined value.
          # @param delete_sources [Boolean] Whether to delete the source fields after combining their values into the target field. If target field name is the same as one of the source fields, the target field is not deleted.
          def initialize(sources:, target:, sep:, prepend_source_field_name: false, delete_sources: true)
            @sources = sources
            @target = target
            @sep = sep
            @del = delete_sources
            @prepend = prepend_source_field_name
          end

          # @private
          def process(row)
            vals = @sources.map { |src| row.fetch(src, nil) }
                           .map { |v| v.blank? ? nil : v }

            if @prepend
              pvals = []
              vals.each_with_index do |val, i|
                val = "#{@sources[i]}: #{val}" unless val.nil?
                pvals << val
              end
              vals = pvals
            end
            val = vals.compact.join(@sep)
            row[@target] = val.empty? ? nil : val

            @sources.each { |src| row.delete(src) unless src == @target } if @del
            row
          end
        end

        # Concatenates values of all fields in each record together into the target field, using the given string as value separator in the combined value
        #
        # # Example
        #
        # Input table:
        #
        # ```
        # | name   | sex | source  |
        # |--------+-----+---------|
        # | Weddy  | m   | adopted |
        # | Niblet | f   | hatched |
        # | Keet   | nil | hatched |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform CombineValues::FullRecord, target: :index
        # ```
        #
        # Results in:
        #
        # ```
        # | name   | sex | source  | index            |
        # |--------+-----+---------+------------------|
        # | Weddy  | m   | adopted | Weddy m adopted  |
        # | Niblet | f   | hatched | Niblet f hatched |
        # | Keet   | nil | hatched | Keet hatched     |
        # ```
        class FullRecord
          # @param target [Symbol] Field into which to write full record
          # @param sep [String] Value used to separate individual field values in combined target field
          def initialize(target:, sep: ' ')
            @target = target
            @sep = sep
          end

          # @private
          def process(row)
            vals = row.keys.map { |k| row.fetch(k, nil) }
            vals = vals.compact
            row[@target] = if vals.empty?
                             nil
                           else
                             vals.join(@sep)
                           end
            row
          end
        end
      end
    end
  end
end
