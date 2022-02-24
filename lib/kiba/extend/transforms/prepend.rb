# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that add data to the beginning of a field
      module Prepend
        ::Prepend = Kiba::Extend::Transforms::Prepend
      end
    end
  end
end
