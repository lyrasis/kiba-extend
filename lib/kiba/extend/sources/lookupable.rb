# frozen_string_literal: true

module Kiba
  module Extend
    module Sources
      # Mix-in module for extending sources so that they can be used
      #   (or not) as lookups in jobs
      module Lookupable
        # @return True
        def is_lookupable?
          true
        end

        # @abstract
        # @return Symbol used as key for specifying file options for lookup, if
        #   file options may be passed
        # @return Nil if no file options may be passed
        def lookup_options_key
          raise NotImplementedError,
            ':lookup_options_key must be defined in including class'
        end
      end
    end
  end
end
