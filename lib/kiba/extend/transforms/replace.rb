# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that perform replacements of full field values
      #
      # For finding/replacing within field values, see {Clean::RegexpFindReplaceFieldVals}
      module Replace
        ::Replace = Kiba::Extend::Transforms::Replace
      end
    end
  end
end
