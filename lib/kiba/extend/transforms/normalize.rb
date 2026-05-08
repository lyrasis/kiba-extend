# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that normalize data.
      #
      # See also:
      #
      # - Kiba::Extend::Transforms::Clean::DowncaseFieldValues
      # - Kiba::Extend::Transforms::Cspace::NormalizeForID
      module Normalize
        ::Normalize = Kiba::Extend::Transforms::Normalize
      end
    end
  end
end
