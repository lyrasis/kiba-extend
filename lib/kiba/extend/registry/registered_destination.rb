# frozen_string_literal: true

require_relative 'registered_file'

module Kiba
  module Extend
    # Value object representing a destination file registered in a {Kiba::Extend::FileRegistry}
    class RegisteredDestination < RegisteredFile
      # Arguments for calling Kiba Destination class
      def args
        return [simple_args] unless @data.dest_special_opts

        opts = supported_special_opts
        warn_about_opts if opts.length < @data.dest_special_opts.length
        return [simple_args] if opts.empty?

        [simple_args.merge(supported_special_opts)]
      end

      # Description of file
      #
      # Used in post-processing STDOUT
      def description
        @data.desc
      end

      # Info hash for file
      #
      # @deprecated Use {#description} and {#key} instead
      def info
        { filekey: @key, desc: description }
      end

      # Kiba Destination class to call
      def klass
        @data.dest_class
      end

      private

      def klass_opts
        klass.instance_method(:initialize).parameters.map { |arr| arr[1] }
      end

      def simple_args
        return { filename: path }.merge(options_label(klass) => @data.dest_opt) if @data.dest_opt

        { filename: path }.merge(labeled_options(klass))
      end

      def supported_special_opts
        @data.dest_special_opts.select { |key, _| klass_opts.any?(key) }
      end

      def unsupported_special_opts
        @data.dest_special_opts.reject { |key, _| klass_opts.any?(key) }
      end

      def warn_about_opts
        unsupported_special_opts.each do |opt, _|
          puts "WARNING: Destination file :#{key} is called with special option :#{opt}, which is unsupported by #{klass}"
        end
      end
    end
  end
end
