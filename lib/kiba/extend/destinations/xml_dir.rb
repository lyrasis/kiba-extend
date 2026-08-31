# frozen_string_literal: true

module Kiba
  module Extend
    module Destinations
      # Writes each "row" (XMLDocument) out as its own file in a directory.
      #
      # If the "row" has a usable `.url` (Nokogiri stashes the original
      #   filename there when a Document is parsed from something
      #   path-like, e.g. by {Kiba::Extend::Sources::XmlDir}), that
      #   filename is reused for the output.
      #
      #   *However*, any document constructed on the fly (e.g. a new
      #   document built from XPath queries on others) will NOT have
      #   a filename saved in .url.
      #
      #   To cover that case, we use a counter and do zero-padded
      #   filenames for XMLDocuments that lack a path in the .url
      #   attribute.
      #
      # @note If 2+ XMLDocument objects contain the same base filename
      #   in their .url attribute (e.g. same-named files from different
      #   subdirectories via `recursive: true`), the later outputs will
      #   always clobber the earlier ones.
      # @todo Add collision logic in case, for example, `dir/1.xml` and
      #   `dir/sub/1.xml` both exist.
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
          @counter = 0
          ensure_dir
        end

        # @param row any object responding to `to_xml` (e.g.
        #   `Nokogiri::XML::Document`, `Nokogiri::XML::Node`)
        def write(row)
          @counter += 1
          File.write(filepath(row), row.to_xml)
        end

        def close
        end

        private

        attr_reader :dirpath, :counter

        def filepath(row)
          File.join(dirpath, basename(row))
        end

        def basename(row)
          # try to extract a usable filename if available...
          return File.basename(row.url) if url?(row)
          # ...use numerical fallback if not
          format("%05d.xml", counter)
        end

        def url?(row)
          row.respond_to?(:url) && !row.url.to_s.empty?
        end

        # We need to override this function because it looks like
        # the superclass function deals with a single file and tries
        # to figure out whether its parent directory exists first.
        #
        # To be clear, the logic is: if we require a path (and yes,
        # we do), we assume that we've been given a directory as
        # `dirpath`, and we try to create that directory unless
        # it's already there.
        def ensure_dir
          return unless self.class.requires_path?
          FileUtils.mkdir_p(dirpath) unless Dir.exist?(dirpath)
        end
      end
    end
  end
end
