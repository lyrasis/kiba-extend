# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations to streamline reporting tasks
      module Report
        ::Report = Kiba::Extend::Transforms::Report
      end
    end
  end
end
