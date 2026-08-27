# frozen_string_literal: true

require "nokogiri"

module Kiba
  module Extend
    module Sources
      class XmlDir
        extend Sourceable
        include ::Enumerable

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

        # @param dirpath [String] path to a directory containing XML
        #   files (one valid XML document per file). Required.
        # @param recursive [Boolean] whether to load all subdirectories
        #   of the specified `dirpath`. Defaults to `false`.
        # @param filesuffixes [Array<String>] Load only files with the
        #   specified suffix(es). Defaults to `[".xml"]`.
        # @param silent_warnings [Boolean] Nokogiri is happy to yield Documents
        #   from invalid XML. Everything in the source directory *should*
        #   be validated before kiba-extend sees it, but we can warn
        #   about errors if needed. Defaults to `false`.
        def initialize(dirpath:, recursive: false, filesuffixes: [".xml"],
          silent_warnings: false)
          @path = File.expand_path(dirpath)
          @recursive = recursive
          @filesuffixes = filesuffixes
          @silent_warnings = silent_warnings
        end

        # Yields one Nokogiri::XML::Document per file. Warns on stdout
        # for any file that fails to parse as well-formed XML (if
        # silent_warnings is `true`), but still yields the (invalid)
        # document and continues
        def each
          file_list.each do |filepath|
            doc = Nokogiri::XML(File.open(filepath))
            warn_invalid(filepath, doc) if doc.errors.any?
            yield doc
          end
        end

        private

        attr_reader :path, :recursive, :filesuffixes, :silent_warnings

        # @param fpath [String] file that raised the errors.
        # @param doc [Nokogiri::XML::Document] the (invalid) Document
        #   that resulted from loading the file at `fpath`.
        def warn_invalid(fpath, doc)
          if silent_warnings == false
            puts "WARNING: #{fpath} is not well-formed XML "\
              "(#{doc.errors.length} error(s)): #{doc.errors.join("; ")}"
          end
        end

        # == Convenience functions ==
        def dir_file_list
          Pathname.new(path).children
        end

        def recursive_file_list
          Pathname.new(path).glob("**/*")
        end

        def suffix_matches(paths)
          paths.select { |fp| fp.file? && filesuffixes.any?(fp.extname) }
        end

        def file_list
          suffix_matches(recursive ? recursive_file_list : dir_file_list)
        end
      end
    end
  end
end
