# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that create warnings, but do not otherwise change data
      module Warn
        ::Warn = Kiba::Extend::Transforms::Warn
      end
    end
  end
end
