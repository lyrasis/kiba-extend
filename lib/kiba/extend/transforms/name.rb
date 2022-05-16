# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that manipulate name data
      #
      # @since 2.8.0
      module Name
        ::Name = Kiba::Extend::Transforms::Name
      end
    end
  end
end
