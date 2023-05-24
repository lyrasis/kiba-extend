# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transforms to sort rows.
      #
      # @note These will have to hold all rows in memory, so may cause
      #   performance issues or crashes for extremely large data sets
      module Sort
        ::Sort = Kiba::Extend::Transforms::Sort
      end
    end
  end
end
