# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module CombineValues
        # Combine values from given fields into the target field.
        #
        # This is like the CONCATENATE function in many spreadsheets. The given
        #   `sep` value is used as a separator between the combined values.
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
          include SepDeprecatable

          # @param sources [Array<Symbol>] Fields whose values are to be
          #   combined
          # @param target [Symbol] Field into which the combined value will be
          #   written. May be one of the source fields
          # @param sep [String] Will be deprecated in a future version. Do not
          #   use.
          # @param delim [String] Value used to separate individual field values
          #   in combined target field
          # @param prepend_source_field_name [Boolean] Whether to insert the
          #   source field name before its value in the combined value.
          # @param delete_sources [Boolean] Whether to delete the source fields
          #   after combining their values into the target field. If target
          #   field name is the same as one of the source fields, the target
          #   field is not deleted.
          def initialize(sources:, target:, sep: nil, delim: nil,
                         prepend_source_field_name: false, delete_sources: true)
            @sources = sources
            @target = target
            @delim = usedelim(sepval: sep, delimval: delim, calledby: self)
            @del = delete_sources
            @prepend = prepend_source_field_name
          end

          # @param row [Hash{ Symbol => String, nil }]
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
            val = vals.compact.join(@delim)
            row[@target] = val.empty? ? nil : val

            @sources.each { |src| row.delete(src) unless src == @target } if @del
            row
          end
        end
      end
    end
  end
end
