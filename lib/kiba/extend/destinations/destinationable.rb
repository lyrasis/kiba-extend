# frozen_string_literal: true

require "fileutils"
require "pathname"

module Kiba
  module Extend
    module Destinations
      # Mix-in module for extending destinations so they can be set up in
      #   jobs
      #
      # @since 4.0.0
      module Destinationable
        def self.included(base)
          base.extend(Kiba::Extend::Registry::Fileable)
        end

        # @return Constant if there is a {Kiba::Extend::Sources} class
        #   for reading the output of jobs that have this class as their
        #   destination
        # @return Nil if results of a job with this destination cannot be
        #   used as a source for another job
        def self.as_source_class
          raise NotImplementedError,
            ":as_source_class must be defined in extending class"
        end

        # @return true
        def self.is_destination? = true

        # @return Array of defined special options for class
        def self.special_options
          raise NotImplementedError,
            ":special_options must be defined in extending class"
        end

        def ensure_dir
          return unless self.class.requires_path?

          dir = Pathname.new(send(self.class.path_key)).dirname
          return if Dir.exist?(dir)

          FileUtils.mkdir_p(dir)
        end
      end
    end
  end
end
