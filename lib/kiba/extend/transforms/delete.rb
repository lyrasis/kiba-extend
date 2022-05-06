# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Tranformations to delete fields and field values
      module Delete
        ::Delete = Kiba::Extend::Transforms::Delete          
      end
    end
  end
end
