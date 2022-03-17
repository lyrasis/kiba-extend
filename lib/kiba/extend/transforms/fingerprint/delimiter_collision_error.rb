# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Fingerprint
        # Is raised if the `delim` passed to {Add} conflicts with `Kiba::Extend.delim` or `Kiba::Extend.sgdelim`
        class DelimiterCollisionError < StandardError
          def initialize(msg = "To avoid treating multi-value field values as separate fields, you must choose a delimiter other than #{Kiba::Extend.delim} or #{Kiba::Extend.sgdelim}")
            super
          end
        end
      end
    end
  end
end


