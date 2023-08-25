# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that perform replacements of full field values
      #
      # rubocop:todo Layout/LineLength
      # For finding/replacing within field values, see {Clean::RegexpFindReplaceFieldVals}
      # rubocop:enable Layout/LineLength
      module Replace
        ::Replace = Kiba::Extend::Transforms::Replace
      end
    end
  end
end
