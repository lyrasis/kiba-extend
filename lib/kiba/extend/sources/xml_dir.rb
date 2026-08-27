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
            Kiba::Extend.xmlopts
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
        # @param silent_warnings [Boolean] Whether to suppress warnings for
        #   invalid XML. Invalid XML files are skipped (no document yielded)
        #   so that callers can depend on valid Nokogiri::XML::Documents
        #   from the XmlDir source. Everything in the source directory
        #   *should* be validated before kiba-extend sees it, but we can
        #   warn about errors if needed. Defaults to `false`.
        # @param parseopts [Integer, Nokogiri::XML::ParseOptions] passed
        #   to `Nokogiri::XML::Document.parse` as the `options` argument.
        #   Defaults to `Kiba::Extend.xmlopts`. NOTE that invalid XML
        #   will break the source unless RECOVER is in xmlopts! (It is
        #   by default, but it should always be included when callers
        #   override @parseopts
        # @param remove_namespaces [Boolean] whether to call
        #   `remove_namespaces!` on each parsed Document before yielding
        #   it. This strips all namespace prefixes/declarations, which
        #   simplifies XPath/CSS queries in transforms at the cost of
        #   losing the ability to distinguish elements/attributes that
        #   differ ONLY by namespace. Defaults to `false`.
        def initialize(dirpath:, recursive: false, filesuffixes: [".xml"],
          silent_warnings: false, parseopts: Kiba::Extend.xmlopts,
          remove_namespaces: false)
          @path = File.expand_path(dirpath)
          @recursive = recursive
          @filesuffixes = filesuffixes
          @silent_warnings = silent_warnings
          @parseopts = parseopts
          @remove_namespaces = remove_namespaces
        end

        # Yields one Nokogiri::XML::Document per file. Warns on stdout
        # for any file that fails to parse as well-formed XML (unless
        # silent_warnings is `true`), and skips yielding a document
        # for that file.
        #
        # Strips namespaces if remove_namespaces is true (but after
        # error checking)
        def each
          file_list.each do |filepath|
            doc = parse(filepath)
            next unless doc

            if doc.errors.any?
              warn_invalid(filepath, doc.errors)
              next
            end
            doc.remove_namespaces! if remove_namespaces
            yield doc
          end
        end

        private

        attr_reader :path, :recursive, :filesuffixes, :silent_warnings,
          :parseopts, :remove_namespaces

        # @param filepath [String] file to parse.
        # @return [Nokogiri::XML::Document, nil] `nil` if parseopts has
        #   been overridden without RECOVER and the file is malformed
        #   (Nokogiri raises rather than collecting errors in that case).
        def parse(filepath)
          Nokogiri::XML::Document.parse(File.open(filepath), nil, "UTF-8",
            parseopts)
        rescue Nokogiri::XML::SyntaxError => e
          warn_invalid(filepath, [e])
          nil
        end

        # @param fpath [String] file that raised the errors.
        # @param errors [Array<Nokogiri::XML::SyntaxError>]
        # TK: option to tee this to a log file?
        def warn_invalid(fpath, errors)
          return if silent_warnings

          puts "WARNING: #{fpath} is not well-formed XML "\
            "(#{errors.length} error(s)): #{errors.join("; ")}"
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
