# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that add data from outside the data source
      #
      # Some other groups of transforms add specific kinds of external data:
      # @see Count
      module Merge
        ::Merge = Kiba::Extend::Transforms::Merge

        # @deprecated Use {Count::MatchingRowsInLookup} instead.
        CountOfMatchingRows = Count::MatchingRowsInLookup
      end
    end
  end
end
