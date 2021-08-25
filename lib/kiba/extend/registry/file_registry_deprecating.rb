require_relative 'registered_source'
require_relative 'registered_lookup'
require_relative 'registered_destination'

module Kiba
  module Extend
    # Transforms a file_registry hash (like {Fwm#registry}) into an object that can return
    #   source, lookup, or destination config for that file, for passing to jobs
    class FileRegistryDeprecating
      def initialize(registry_hash)
        @reghash = registry_hash
      end

      def as_destination(filekey)
        Kiba::Extend::RegisteredDestination.new(key: built_key(filekey), data: lookup(filekey))
      end

      def as_lookup(filekey)
        Kiba::Extend::RegisteredLookup.new(key: built_key(filekey), data: lookup(filekey))
      end
      
      def as_source(filekey)
        Kiba::Extend::RegisteredSource.new(key: built_key(filekey), data: lookup(filekey))
      end

      def files
        @files ||= traverse_files
      end
      
      def generated_files
        
      end

      private

      def built_key(filekey)
        key = filekey.is_a?(Symbol) ? [filekey] : filekey
        key.map(&:to_s).join('/').to_sym
      end

      def lookup(filekey)
        @reghash.dig(*filekey)
      end

      def traverse_files
      end

      def convert_to_ostruct_recursive(obj, options)
        result = obj
        if result.is_a? Hash
          result = result.dup.with_sym_keys
          result.each  do |key, val| 
            result[key] = convert_to_ostruct_recursive(val, options) unless options[:exclude].try(:include?, key)
          end
          result = OpenStruct.new result       
        elsif result.is_a? Array
          result = result.map { |r| convert_to_ostruct_recursive(r, options) }
        end
        return result
      end
    end
  end
end
