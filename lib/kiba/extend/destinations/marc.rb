# frozen_string_literal: true

require "marc"

module Kiba
  module Extend
    module Destinations
      # Writes MARC records to a file
      #
      # This is a wrapper around `ruby-marc`'s `MARC::Writer`, so see
      #   relevant documentation in:
      #   https://github.com/ruby-marc/ruby-marc/blob/main/lib/marc/writer.rb
      #
      # @since 4.0.0
      class Marc
        extend Destinationable

        class << self
          def as_source_class = Kiba::Extend::Sources::Marc

          def default_file_options = nil

          def options_key = nil

          def path_key = :filename

          def requires_path? = true

          def special_options = [:allow_oversized]
        end

        # @param filename [String] path for writing MARC file
        # @param allow_oversized [Boolean, nil] If given, will set
        #   MARC::Writer's `allow_oversized` attribute. **Set in registry
        #   entry's `dest_special_opts`**
        def initialize(filename:, allow_oversized: nil)
          @writer = MARC::Writer.new(filename)
          writer.allow_oversized = allow_oversized if allow_oversized
        end

        # @param record [MARC::Record]
        def write(record)
          writer.write(record)
        end

        # @private
        def close
          writer.close
        end

        private

        attr_reader :writer
      end
    end
  end
end
