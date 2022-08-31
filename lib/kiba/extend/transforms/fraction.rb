# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transforms to deal with fractions in field values
      module Fraction
        ::Fraction = Kiba::Extend::Transforms::Fraction
      end
    end
  end
end
