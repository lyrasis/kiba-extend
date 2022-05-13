# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        class RowSelector
          class << self
          def call(conditions: {}, sep: nil)
            if conditions.is_a?(Hash)
              Kiba::Extend::Utils::Lookup::RowSelectorByHash.new(
                conditions: conditions,
                sep: sep
                )
            end
          end            
          end
        end
      end
    end
  end
end

  
