# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # utility functions across Transforms
      module Helpers
        module_function

        # rubocop:todo Layout/LineLength
        # Indicates whether a given value is empty, ignoring delimiters. If `usenull` is true,
        # rubocop:enable Layout/LineLength
        #   the config.nullvalue string is treated as empty
        # @param val [String] The field value to check
        # rubocop:todo Layout/LineLength
        # @param usenull [Boolean] If true, replaces config.nullvalue string with '' to make determination
        # rubocop:enable Layout/LineLength
        def empty?(val, usenull = false)
          return true if val.nil?

          chkval = usenull ? val.gsub(Kiba::Extend.nullvalue, "") : val

          chkval.strip.empty?
        end

        # @param field_vals [Hash{Symbol=>String,Nil}l] A subset of a row
        # rubocop:todo Layout/LineLength
        # @param discard [:nil, :empty, :delim] Types of field values to remove from returned hash
        # rubocop:enable Layout/LineLength
        # @param delim [String] Multivalue delimiter used to split fields
        # rubocop:todo Layout/LineLength
        # @param usenull [Boolean] If true, replaces '%NULLVALUE%' with '' to make determination
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # @return [Array(Symbol)] of names of fields that should be kept, based on given discard
        # rubocop:enable Layout/LineLength
        #   and usenull param values and the field values
        private_class_method def keep_fields(field_vals, discard, delim,
          usenull)
          if usenull
            field_vals = field_vals.transform_values { |val|
              val.gsub(Kiba::Extend.nullvalue, "")
            }
          end
          if discard.any?(:empty)
            field_vals = field_vals.reject { |_field, val|
              val.empty?
            }
          end
          if discard.any?(:delim)
            field_vals = field_vals.reject { |_field, val|
              delim_only?(val, delim)
            }
          end
          field_vals.keys
        end
      end
    end
  end
end
