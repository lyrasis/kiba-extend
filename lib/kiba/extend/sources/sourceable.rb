# frozen_string_literal: true

module Kiba
  module Extend
    module Sources
      # Mix-in module for extending sources so they can be used as sources
      #   in jobs
      module Sourceable
        include Kiba::Extend::Registry::Fileable

        # @return true
        def is_source?
          true
        end
      end
    end
  end
end
