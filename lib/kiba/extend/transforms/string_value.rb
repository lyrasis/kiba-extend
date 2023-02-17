# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transforms to convert String values in fields to other types
      # @since 3.3.0
      module StringValue
        ::StringValue = Kiba::Extend::Transforms::StringValue
      end
    end
  end
end
