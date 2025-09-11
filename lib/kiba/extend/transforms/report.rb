# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations to streamline reporting tasks
      # @since 5.0.0
      module Report
        ::Report = Kiba::Extend::Transforms::Report
      end
    end
  end
end
