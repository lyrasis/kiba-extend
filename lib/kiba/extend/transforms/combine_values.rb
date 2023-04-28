# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transforms that join values from multiple fields into one field value
      module CombineValues
        ::CombineValues = Kiba::Extend::Transforms::CombineValues
      end
    end
  end
end
