# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Namespace for transforms that generate ID values
      module IdGenerator
        ::IdGenerator = Kiba::Extend::Transforms::IdGenerator
      end
    end
  end
end
