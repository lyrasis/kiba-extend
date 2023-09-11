# frozen_string_literal: true

module Kiba
  module Extend
    module Destinations
      # Mix-in module for extending destinations so they can be set up in
      #   jobs
      #
      # @since 4.0.0
      module Destinationable
        include Kiba::Extend::Registry::Fileable
        # @return Constant if there is a {Kiba::Extend::Sources} class
        #   for reading the output of jobs that have this class as their
        #   destination
        # @return Nil if results of a job with this destination cannot be
        #   used as a source for another job
        def as_source_class
          raise NotImplementedError,
            ":as_source_class must be defined in extending class"
        end

        # @return true
        def is_destination?
          true
        end

        # @return Array of defined special options for class
        def special_options
          raise NotImplementedError,
            ":special_options must be defined in extending class"
        end
      end
    end
  end
end
