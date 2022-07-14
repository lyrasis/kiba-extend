# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Helpers
        # Returns values of specfied fields that meet the specified criteria
        class FieldValueGetter
          # @param fields [Array(Symbol)] from which to return values
          # @param delim [String]
          # @param discard [Array(:nil, :empty, :delim)] values to discard from returned results. `:nil` and
          #   `:empty` are self-explanatory. `:delim` causes delimiter-only fields to be discarded. See
          #   {DelimOnlyChecker} for how delimiter-only status is determined.
          # @param treat_as_null [nil, String, Array(String)] value(s) to treat as null/empty when determining
          #   what to discard
          def initialize(fields:, delim: Kiba::Extend.delim, discard: %i[nil empty delim], treat_as_null: nil)
            @fields = [fields].flatten
            @delim = delim
            @discard = discard
            @null_vals = treat_as_null ? [treat_as_null].flatten.sort_by{ |v| v.length }.reverse : []
            @delim_only_checker = DelimOnlyChecker.new(delim: delim, treat_as_null: treat_as_null, blank_result: false)
          end

          def call(row)
            raw = fields.map{ |field| [field, row[field]] }.to_h
            null_cleaned = null_vals.empty? ? raw : clean_nulls(raw)
            nil_removed = discard.any?(:nil) ? remove_nils(null_cleaned) : null_cleaned
            empty_removed = discard.any?(:empty) ? remove_empty(nil_removed) : nil_removed
            delim_only_removed = discard.any?(:delim) ? remove_delim_only(empty_removed) : empty_removed
            delim_only_removed.keys.map{ |field| [field, row[field]] }.to_h
          end
          
          private

          attr_reader :fields, :delim, :discard, :null_vals, :delim_only_checker

          def clean_nulls(vals)
            return vals if discard.empty?
            
            vals.map{ |field, val| [field, replace_nulls_in_val(val)] }.to_h
          end

          def remove_delim_only(vals)
            vals.reject{ |field, val| delim_only_checker.call(val) }
          end
          
          def remove_empty(vals)
            vals.reject{ |field, val| val.nil? ? false : val.empty? }
          end

          def remove_nils(vals)
            vals.reject{ |field, val| val.nil? }
          end

          def replace_nulls_in_val(val)
            null_vals.each{ |nv| val.nil? ? val : val = val.gsub(nv, '').strip }
            val
          end
        end
      end
    end
  end
end
