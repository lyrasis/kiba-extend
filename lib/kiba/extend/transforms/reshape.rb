# frozen_string_literal: true

# rubocop:todo Layout/LineLength

module Kiba
  module Extend
    module Transforms
      # Transformations which significantly change the shape of the data without adding new rows.
      #
      # ## See also:
      #
      # - {Kiba::Extend::Transforms::Collapse} transforms, which reduce the number of fields by combining
      #   them in various ways
      # - {Kiba::Extend::Transforms::Explode} transforms, which change the shape **and add new rows**
      module Reshape
        ::Reshape = Kiba::Extend::Transforms::Reshape
      end
    end
  end
end
# rubocop:enable Layout/LineLength
