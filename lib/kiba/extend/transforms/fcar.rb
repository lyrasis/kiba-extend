# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Namespace for transformations to prepare and merge FCAR (facilitated
      #   cleanup and remapping) worksheets into projects
      module Fcar
        ::Fcar = Kiba::Extend::Transforms::Fcar
      end
    end
  end
end
