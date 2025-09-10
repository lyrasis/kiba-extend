# frozen_string_literal: true

require_relative "registered_file"

module Kiba
  module Extend
    module Registry
      # Value object representing a destination file registered in a
      #   {Kiba::Extend::FileRegistry}
      class RegisteredDestination < RegisteredFile
        class SuppliedEntryError < TypeError
          include Kiba::Extend::ErrMod

          def initialize(entry_key)
            super("Registry entry #{entry_key} is a supplied entry, so it "\
                  "cannot be used as a job destination")
          end
        end

        def initialize(key:, data:, for_job:)
          super
          fail SuppliedEntryError.new(key) if supplied
        end

        # Arguments for calling Kiba Destination class
        def args
          return simple_args unless dest_special_opts

          opts = supported_special_opts
          warn_about_opts if opts.length < dest_special_opts.length
          return simple_args if opts.empty?

          simple_args.merge(supported_special_opts)
        end

        # Description of file
        #
        # Used in post-processing STDOUT
        def description
          desc
        end

        def klass
          dest_class
        end

        private

        def dest_opts
          return {dest_class.options_key => dest_opt} if dest_opt

          dest_class.labeled_options
        end

        def simple_args
          {dest_class.path_key => path}.merge(dest_opts)
        end

        def supported_special_opts
          dest_special_opts.select do |key, _|
            dest_class.special_options.any?(key)
          end
        end

        def unsupported_special_opts
          dest_special_opts.reject do |key, _|
            dest_class.special_options.any?(key)
          end
        end

        def warn_about_opts
          unsupported_special_opts.each do |opt, _|
            puts "WARNING: Destination file :#{key} is called with special "\
              "option :#{opt}, which is unsupported by #{dest_class}"
          end
        end
      end
    end
  end
end
