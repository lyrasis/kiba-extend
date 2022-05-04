# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that change the name(s) of elements in the data
      module Rename
        ::Rename = Kiba::Extend::Transforms::Rename
      end
    end
  end
end
