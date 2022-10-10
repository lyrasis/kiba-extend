# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transforms to convert String values in fields to other types
      module StringValue
        ::StringValue = Kiba::Extend::Transforms::StringValue
      end
    end
  end
end
