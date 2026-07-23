# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Namespace for transformations to prepare and merge FCAR (facilitated
      #   cleanup and remapping) worksheets into projects
      # @since 7.0.0
      module StandardFcar
        ::StandardFcar = Kiba::Extend::Transforms::StandardFcar
      end
    end
  end
end
