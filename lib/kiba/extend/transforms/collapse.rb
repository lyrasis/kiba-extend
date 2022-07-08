# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transforms that turn fields or values into a smaller number of fields or values
      #
      # ## See also
      #
      # - {{Kiba::Extend::Transforms::Take}} transforms, which select a single value from multivalue
      #   fields
      # - {{Kiba::Extend::Transforms::FilterRows}} transforms, which can be used to conditionally
      #   remove rows from a job
      # - {{Kiba::Extend::Transforms::Extract}} transforms, which can produce subsets of data
      module Collapse
        ::Collapse = Kiba::Extend::Transforms::Collapse
      end
    end
  end
end
