# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # rubocop:todo Layout/LineLength
      # Transforms that turn fields or values into a smaller number of fields or values
      # rubocop:enable Layout/LineLength
      #
      # ## See also
      #
      # rubocop:todo Layout/LineLength
      # - {Kiba::Extend::Transforms::Take} transforms, which select a single value from multivalue
      # rubocop:enable Layout/LineLength
      #   fields
      # rubocop:todo Layout/LineLength
      # - {Kiba::Extend::Transforms::FilterRows} transforms, which can be used to conditionally
      # rubocop:enable Layout/LineLength
      #   remove rows from a job
      # rubocop:todo Layout/LineLength
      # - {Kiba::Extend::Transforms::Extract} transforms, which can produce subsets of data
      # rubocop:enable Layout/LineLength
      module Collapse
        ::Collapse = Kiba::Extend::Transforms::Collapse
      end
    end
  end
end
