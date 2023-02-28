# frozen_string_literal: true

module Kiba
  module Extend
    module Sources
      # Mix-in module for extending sources so they can be used as sources
      #   in jobs
      module Sourceable
        # @param path [String, nil]
        def default_args(path = nil)
          if requires_path? && path.nil?
            fail Kiba::Extend::SourceRequiresPathError
          elsif path.nil?
            labeled_options
          else
            {path_key=>path}.merge(labeled_options)
          end
        end

        # @abstract
        # @return Hash if default file options are configured in the project
        # @return Nil of no default file options are configured
        def default_file_options
          raise NotImplementedError,
            ':default_file_options must be defined in including class'
        end

        # @return Hash of file options
        def labeled_options
          if options_key && default_file_options
            {options_key=>default_file_options}
          else
            {}
          end
        end

        # @abstract
        # @return Symbol used as key for specifying file options, if
        #   file options may be passed
        # @return Nil if no file options may be passed
        def options_key
          raise NotImplementedError,
            ':options_key must be defined in including class'
        end

        # @abstract
        # @return Symbol used as key to indicate source path, if path
        #   is required
        # @return Nil if no path is required
        def path_key
          raise NotImplementedError,
            ':path_key must be defined in including class'
        end

        # @abstract
        # @return Boolean whether path to file must be provided
        def requires_path?
          raise NotImplementedError,
            ':requires_path? must be defined in including class'
        end
      end
    end
  end
end
