# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # utility functions across Transforms
      module Helpers
        module_function
        # @deprecated in 2.9.0. Use {Kiba::Extend::Transforms::Helpers::DelimOnlyChecker} instead. This service
        #   class has slightly different behavior in that it returns true for `nil` or `empty?` values,
        #   however, this does not appear that it has any impact on existing use of this method
        # 
        # Indicates whether a field value is delimiter-only. If `usenull` is set to true, the
        #   config.nullvalue string is treated as empty in detecting delimiter-only-ness
        # @param val [String] The field value to check
        # @param delim [String] The multivalue delimiter
        # @param usenull [Boolean, String] If `true`, replaces config.nullvalue string with '' to make
        #   determination. If `false` no replacement is done. If a String is given, that string is replaced
        #   with '' to make determination. If Array of Strings given, each String is replaced with ''.
        # @return [false] if `value` is nil, empty, or contains characters other than delimiter(s)
        #   and leading/trailing spaces
        # @return [true] if `value` contains only delimiter(s) and leading/trailing spaces
        def delim_only?(val, delim, usenull = false)
          nv = usenull ? Kiba::Extend.nullvalue : nil
          DelimOnlyChecker.call(delim: delim, treat_as_null: nv, value: val)
        end

        # Indicates whether a given value is empty, ignoring delimiters. If `usenull` is true,
        #   the config.nullvalue string is treated as empty
        # @param val [String] The field value to check
        # @param usenull [Boolean] If true, replaces config.nullvalue string with '' to make determination
        def empty?(val, usenull = false)
          return true if val.nil?

          chkval = usenull ? val.gsub(Kiba::Extend.nullvalue, '') : val

          chkval.strip.empty?
        end
          

        # @param row [Hash{Symbol=>String,Nil}l] A row of data
        # @param fields [Array(Symbol)] Names of fields to process
        # @param discard [Array<:nil, :empty, :delim>] Types of field values to remove from returned hash
        # @param delim [String] Multivalue delimiter used to split fields
        # @param usenull [Boolean] If true, replaces '%NULLVALUE%' with '' to make determination
        # @return [Hash{Symbol=>String,Nil}l] of field data for fields that meet keep criteria
        def field_values(row:, fields:, discard: %i[nil empty delim], delim: Kiba::Extend.delim, usenull: false)
          field_vals = fields.map { |field| [field, row.fetch(field, nil)] }.to_h
          return field_vals if discard.blank?

          field_vals = field_vals.reject { |_field, val| val.nil? } if discard.any?(:nil)
          keep = keep_fields(field_vals, discard, delim, usenull)
          field_vals.select { |field, _val| keep.any?(field) }
        end

        # @param field_vals [Hash{Symbol=>String,Nil}l] A subset of a row
        # @param discard [:nil, :empty, :delim] Types of field values to remove from returned hash
        # @param delim [String] Multivalue delimiter used to split fields
        # @param usenull [Boolean] If true, replaces '%NULLVALUE%' with '' to make determination
        # @return [Array(Symbol)] of names of fields that should be kept, based on given discard
        #   and usenull param values and the field values
        private_class_method def keep_fields(field_vals, discard, delim, usenull)
          field_vals = field_vals.transform_values { |val| val.gsub(Kiba::Extend.nullvalue, '') } if usenull
          field_vals = field_vals.reject { |_field, val| val.empty? } if discard.any?(:empty)
          field_vals = field_vals.reject { |_field, val| delim_only?(val, delim) } if discard.any?(:delim)
          field_vals.keys
        end
      end
    end
  end
end
