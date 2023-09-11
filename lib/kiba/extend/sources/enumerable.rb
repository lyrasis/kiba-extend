# frozen_string_literal: true

module Kiba
  module Extend
    module Sources
      # Extension of `Kiba::Common::Sources::Enumerable`, adding methods
      #   supporting use as a source in registry entries
      #
      # @since 4.0.0
      class Enumerable < Kiba::Common::Sources::Enumerable
        extend Sourceable

        class << self
          def default_file_options
            nil
          end

          def options_key
            nil
          end

          def path_key
            nil
          end

          def requires_path?
            false
          end
        end
      end
    end
  end
end
