# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Namespace for transforms that add values to the end of fields or rows
      module Append
        ::Append = Kiba::Extend::Transforms::Append
      end
    end
  end
end
