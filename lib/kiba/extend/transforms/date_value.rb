# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Tranformations that manipulate date values
      module DateValue
        ::DateValue = Kiba::Extend::Transforms::DateValue
      end
    end
  end
end
