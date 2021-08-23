module Kiba
  module Extend
    # Transforms a file_registry hash (like {Fwm#registry}) into an object that can return
    #   source, lookup, or destination config for that file, for passing to jobs
    class FileRegistry
      class FileNotFoundError < StandardError
        def initialize(filekey)
          msg = ":#{filekey} not found as key in file registry hash"
          super(msg)
        end
      end
      
      def initialize(registry_hash)
        @reghash = registry_hash
      end

      def as_destination(filekey)
        file = lookup(filekey)
        {
          klass: file[:dest_class],
          args: {filename: file[:path], csv_options: file[:dest_opt]},
          info: {filekey: filekey, desc: file[:desc]}
        }
      end

      def as_lookup(filekey)
        file = lookup(filekey)
        result = {
          args: {file: file[:path], csvopt: file[:src_opt], keycolumn: file[:key]},
          info: {filekey: filekey, desc: file[:desc]},
        }
        add_require(result, file)
      end
      
      def as_source(filekey)
        file = lookup(filekey)
        path = file[:path]
        result = {
          klass: file[:src_class],
          args: {filename: path, csv_options: file[:src_opt]},
          info: {filekey: filekey, desc: file[:desc]},
        }
        add_require(result, file)
      end

      private

      def add_require(result, file)
        return result if File.exist?(file[:path])

        result[:require] = { module: file[:creator_module], method: file[:creator_method] }
        result
      end

      def lookup(filekey)
        file = @reghash[filekey]
        raise FileNotFoundError, filekey if file.nil?

        file
      end
    end
  end
end
