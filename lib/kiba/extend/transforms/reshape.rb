# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # rubocop:todo Layout/LineLength
      # Transformations which significantly change the shape of the data without adding new rows.
      # rubocop:enable Layout/LineLength
      #
      # ## See also:
      #
      # rubocop:todo Layout/LineLength
      # - {Kiba::Extend::Transforms::Collapse} transforms, which reduce the number of fields by combining
      # rubocop:enable Layout/LineLength
      #   them in various ways
      # rubocop:todo Layout/LineLength
      # - {Kiba::Extend::Transforms::Explode} transforms, which change the shape **and add new rows**
      # rubocop:enable Layout/LineLength
      module Reshape
        ::Reshape = Kiba::Extend::Transforms::Reshape
      end
    end
  end
end
