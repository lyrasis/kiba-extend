# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that reshape the data, creating new rows.
      #
      # See {Reshape} for transformations that reshape without adding rows.
      module Explode
        ::Explode = Kiba::Extend::Transforms::Explode
      end
    end
  end
end
