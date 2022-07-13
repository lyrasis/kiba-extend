# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Clean
        # @deprecated in 2.9.0. Use {Delete::DelimiterOnlyFieldValues} instead
        class DelimiterOnlyFields
          include Kiba::Extend::Transforms::Helpers
          def initialize(delim:, use_nullvalue: false)
            @delim = delim
            @use_nullvalue = use_nullvalue
          end

          # @private
          def process(row)
            row.each do |hdr, val|
              row[hdr] = nil if val.is_a?(String) && delim_only?(val, @delim, @use_nullvalue)
            end
            row
          end
        end
      end
    end
  end
end
