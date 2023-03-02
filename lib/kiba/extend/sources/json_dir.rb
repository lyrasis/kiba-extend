# frozen_string_literal: true

require 'json'
require 'pathname'

module Kiba
  module Extend
    module Sources
      # Given path to a directory, JSON parses each file matching given
      #   specifications, and returns the result as a Hash with empty values
      #   converted to `nil`
      #
      # @note May return Hashes having different keys, which will cause problems
      #   writing out to {Kiba::Extend::Destinations::CSV}, which expects all
      #   rows to have the same headers/fields. Using
      #   {Kiba::Extend::Transforms::Clean::EnsureConsistentFields} in any job
      #   that has a {JsonDir} source and a {Kiba::Extend::Destinations::CSV}
      #   destination will protect against these errors.
      #   {Kiba::Extend::Jobs::JsonToCsvJob} runs this transform automatically
      #   as the last step before writing out rows
      class JsonDir
        extend Sourceable

        class << self
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
        end

        # @param dirpath [String] path of directory containing JSON files
        # @param recursive [Boolean] Whether to include eligible JSON
        #   files in subdirectories
        # @param filesuffixes [Array<String>] to read in as
        #   JSON records. Include preceding period
        def initialize(dirpath:, recursive: false, filesuffixes: ['.json'])
          @path = File.expand_path(dirpath)
          @recursive = recursive
          @filesuffixes = filesuffixes
        end

        def each
          file_list.each do |path|
            jsonhash = parse_json(path)
            if jsonhash
              yield jsonhash
            else
              warn("Cannot read/parse #{path}")
            end
          end
        end

        private

        attr_reader :path, :recursive, :filesuffixes

        def file_list
          suffix_matches(recursive ? recursive_file_list : dir_file_list)
        end

        def dir_file_list
          Pathname.new(path)
            .children
        end

        def parse_json(path)
          JSON.parse(File.read(path))
            .transform_values{ |val| val.empty? ? nil : val }
            .transform_keys{ |key| key.downcase.to_sym }
        rescue StandardError
          nil
        end

        def recursive_file_list
          Pathname.new(path)
            .glob("**/*")
        end

        def suffix_matches(paths)
          paths.select{ |path| path.file? && filesuffixes.any?(path.extname) }
        end
      end
    end
  end
end
