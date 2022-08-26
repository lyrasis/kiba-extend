# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that remove rows based on different types of conditions
      module FilterRows
        ::FilterRows = Kiba::Extend::Transforms::FilterRows
      end
    end
  end
end
