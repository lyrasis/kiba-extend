# frozen_string_literal: true

require "marc"

module Kiba
  module Extend
    module Utils
      # Callable service to clean punctuation off end of name string
      class MarcNameCleaner
        # @param value [String]
        # @return [String]
        def call(value)
          value.sub(/,$/, "")
            .sub(/([^ .].)\.$/, '\1')
            .sub(/,\.?$/, "")
        end
      end
    end
  end
end
