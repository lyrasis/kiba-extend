# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transforms that turn fields or values into a smaller number of fields or values
      module Collapse
        ::Collapse = Kiba::Extend::Transforms::Collapse
      end
    end
  end
end
