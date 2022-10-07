# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transforms to deal with string values in fields
      module StringValue
        ::StringValue = Kiba::Extend::Transforms::StringValue
      end
    end
  end
end
