# frozen_string_literal: true

require "nokogiri"

module Kiba
  module Extend
    module Sources
      class XmlDir
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

        # @param dirpath [String] path to a directory containing XML
        # files, such as EADs
        # @param record_selector [Proc] called with each
        #   Nokogiri::XML::Reader element node; nodes for which this
        #   returns true are yielded as records
        def initialize(
          dirpath:,
          recursive: false,
          filesuffixes: [".xml"],
          record_selector: ->(node) { node.name == "none" && node.depth == 1 }
        )
          @path = File.expand_path(dirpath)
          @recursive = recursive
          @filesuffixes = filesuffixes
          @record_selector = record_selector
        end

        def each
          file_list.each do |path|
            parse_xml(path) { |node| yield node }
          end
        end

        private

        attr_reader :path, :recursive, :filesuffixes

        def parse_xml(path)
          reader = Nokogiri::XML::Reader(File.open(path))
          reader.each do |node|
            # NOTE this rasies on invalid XML, need to rescue and log
            next unless node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
            next unless @record_selector.call(node)
            yield Nokogiri::XML(node.outer_xml)
          end
        end

        def dir_file_list
          Pathname.new(path).children
        end

        def recursive_file_list
          Pathname.new(path).glob("**/*")
        end

        def suffix_matches(paths)
          paths.select { |path| path.file? && filesuffixes.any?(path.extname) }
        end

        def file_list
          suffix_matches(recursive ? recursive_file_list : dir_file_list)
        end
      end
    end
  end
end
