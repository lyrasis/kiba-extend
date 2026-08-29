# frozen_string_literal: true

module Kiba
  module Extend
    module Jobs
      # Job with one MARC source, one destination, and zero-to-n lookups.
      #
      # @note The first transform called in a `MarcJob` must be one from the
      #   {Kiba::Extend::Transforms::Marc} namespace. Like {XmlJob}, this is
      #   essentially just an empty template (in this case, it helps preserve
      #   compatibility with existing kiba-extend projects' code).
      # @since 3.3.0
      class MarcJob < AbstractNoInitialDataConversionJob
      end
    end
  end
end
