#require_relative 'registered_source'
require_relative 'registered_lookup'
require_relative 'registered_destination'

module Kiba
  module Extend
    # Transforms a file_registry hash (like {Fwm#registry}) into an object that can return
    #   source, lookup, or destination config for that file, for passing to jobs
    class FileRegistry      
      def initialize(registry_hash)
        @reghash = registry_hash
 #       @source = Kiba::Extend::RegisteredSource.new

  #      @lookup = 
      end

      def as_destination(filekey)
        Kiba::Extend::RegisteredDestination.new(key: filekey, data: @reghash[filekey])
      end

      def as_lookup(filekey)
        Kiba::Extend::RegisteredLookup.new(key: filekey, data: @reghash[filekey])
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
