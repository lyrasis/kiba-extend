# frozen_string_literal: true

module Kiba
  module Extend
    # Reusable data sources for use with Kiba
    module Sources
      # Selects multiple files from a directory, with an option to do so recursively. Supports include/exclude glob filters
      class FileSet
        attr_reader :files

        def initialize(path:, recursive: false, include: nil, exclude: nil)
          @path = path
          @recurse = recursive
          @include = include
          @exclude = exclude
          @files = select_files
        end

        private

        def select_files
          if @recurse
            files = Dir.glob("#{@path}/**/*").sort
          else
            files = Dir.children(@path).sort
          end
          files = files.select { |file| File.basename(file).match(Regexp.new(@include)) } if @include
          files = files.reject { |file| File.basename(file).match(Regexp.new(@exclude)) } if @exclude
          files
        end
      end
    end
  end
end
