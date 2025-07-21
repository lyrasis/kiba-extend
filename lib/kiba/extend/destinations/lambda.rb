# frozen_string_literal: true

module Kiba
  module Extend
    module Destinations
      # Wrapper around `Kiba::Common::Destinations::Lambda`
      #
      # @since 4.0.0
      class Lambda < Kiba::Common::Destinations::Lambda
        extend Destinationable

        class << self
          def as_source_class = nil

          def default_file_options = Kiba::Extend.lambdaopts

          def options_key = :options

          def path_key = nil

          def requires_path? = false

          def special_options = []
        end
      end
    end
  end
end
