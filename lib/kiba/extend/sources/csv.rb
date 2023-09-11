# frozen_string_literal: true

module Kiba
  module Extend
    module Sources
      # Extension of `Kiba::Common::Sources::CSV`, adding methods that support
      #   use as a source in registry entries
      #
      # @since 4.0.0
      class CSV < Kiba::Common::Sources::CSV
        extend Lookupable
        extend Sourceable

        class << self
          def default_file_options
            Kiba::Extend.csvopts
          end

          def lookup_options_key
            :csvopt
          end

          def options_key
            :csv_options
          end

          def path_key
            :filename
          end

          def requires_path?
            true
          end
        end
      end
    end
  end
end
