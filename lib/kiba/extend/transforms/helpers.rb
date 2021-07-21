# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # utility functions across Transforms
      module Helpers
        # Indicates whether a field value is delimiter-only. If `usenull` is set to true, the
        #   %NULLVALUE% string is treated as empty in detecting delimiter-only-ness
        # @param val [String] The field value to check
        # @param delim [String] The multivalue delimiter
        # @param usenull [Boolean] If true, replaces '%NULLVALUE%' with '' to make determination
        # @return [false] if `value` is nil, empty, or contains characters other than delimiter(s)
        #   and leading/trailing spaces
        # @return [true] if `value` contains only delimiter(s) and leading/trailing spaces
        def delim_only?(val, delim, usenull = false)
          return false if val.nil?
          return false if val.strip.empty?
          
          chk = val.gsub(delim, '').strip
          chk = chk.gsub('%NULLVALUE%', '').strip if usenull
          chk.empty?
        end
        
        def hash_field_values(row:, fields:, discard: %i[nil empty delim], usenull: false)
          
        end
      end
    end
  end
end
