# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Fingerprint
        # Raised if the value of any field used to generate a fingerprint contains the fingerprint delimiter
        class DelimiterInValueError < StandardError
        end
      end
    end
  end
end
