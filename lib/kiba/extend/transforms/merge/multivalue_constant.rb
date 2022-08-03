# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Merge
        # Adds a specified value to new target field for every value found in `on_field`
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | name                 |
        # |----------------------|
        # | Weddy                |
        # | NULL                 |
        # |                      |
        # | nil                  |
        # | Earlybird;Divebomber |
        # | ;Niblet              |
        # | Hunter;              |
        # | NULL;Earhart         |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Merge::MultivalueConstant, on_field: :name, target: :species, value: 'guinea fowl', sep: ';',
        #    placeholder: 'NULL'
        # ```
        #
        # Results in:
        #
        # ```
        # | name                 | species                 |
        # |----------------------+-------------------------|
        # | Weddy                | guinea fowl             |
        # | NULL                 | NULL                    |
        # |                      | NULL                    |
        # | nil                  | NULL                    |
        # | Earlybird;Divebomber | guinea fowl;guinea fowl |
        # | ;Niblet              | NULL;guinea fowl        |
        # | Hunter;              | guinea fowl;NULL        |
        # | NULL;Earhart         | NULL;guinea fowl        |
        # ```
        class MultivalueConstant
          # @param on_field [Symbol] field the new field's values will be based on
          # @param target [Symbol] name of new field
          # @param value [String] value to add to `target` for each existing value in `on_field`
          # @param sep [String] multivalue separator
          # @param placeholder [String] value to add to `target` for empty/nil values in `on_field`
          def initialize(on_field:, target:, value:, sep:, placeholder:)
            @on_field = on_field
            @target = target
            @value = value
            @sep = sep
            @placeholder = placeholder
          end

          # @param row [Hash{ Symbol => String }]
          def process(row)
            field_val = row.fetch(@on_field, nil)
            if field_val.blank?
              row[@target] = @placeholder
              return row
            end

            merge_vals = []
            field_val.split(@sep, -1).each do |field_val|
              merge_vals << if field_val == @placeholder || field_val.blank?
                              @placeholder
                            else
                              @value
                            end
            end

            row[@target] = merge_vals.join(@sep)
            row
          end
        end
      end
    end
  end
end
