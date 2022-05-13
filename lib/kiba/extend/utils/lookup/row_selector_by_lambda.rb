# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        class RowSelectorByLambda
          def initialize(conditions: {}, sep: nil)
            @conditions = conditions
            @sep = sep
          end

          def call(origrow:, mergerows:)
            conditions.call(origrow, mergerows)
          end

          private

          attr_reader :conditions, :sep
        end
      end
    end
  end
end

  
