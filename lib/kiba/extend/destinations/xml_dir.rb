# frozen_string_literal: true

module Kiba
  module Extend
    module Destinations
      class XmlDir
        include Destinationable

        class << self
          def as_source_class
            Kiba::Extend::Sources::XmlDir
          end

          def default_file_options
            nil
          end

          def options_key
            nil
          end

          def path_key
            :dirpath
          end

          def requires_path?
            true
          end

          def special_options
            []
          end
        end

        # @param dirpath [String] path to destination directory
        def initialize(dirpath:)
          @dirpath = dirpath
          ensure_dir
        end

        def write(row)
        end

        def close
        end

        private

        attr_reader :dirpath

        # We need to override this function because it looks like
        # the superclass function deals with a single file and tries
        # to figure out whether its parent directory exists first.
        def ensure_dir
          return unless self.class.requires_path?
          FileUtils.mkdir_p(dirpath) unless Dir.exist?(dirpath)
        end
      end
    end
  end
end
