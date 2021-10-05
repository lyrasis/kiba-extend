# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that add count data
      # @see Merge for other transforms that add in data
      module Count
        ::Count = Kiba::Extend::Transforms::Count
      end
    end
  end
end
