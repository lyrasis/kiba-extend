module Kiba
  module Extend
    class RegistryEntrySelector
      # @param cstr [String] stringified class name
      def created_by_class(cstr)
        with_creator.select{ |entry| entry.creator.owner.to_s[cstr] }
      end

      # @param mstr [String] stringified method name
      def created_by_method(mstr)
        matcher = "#<Method: #{mstr}("
        with_creator.select{ |entry| entry.creator.to_s[matcher] }
      end
      


      # Selects entries whose tags include all given tags
      def tagged_all(*args)
        tags = args.flatten.map(&:to_sym)
        tags.inject(Kiba::Extend.registry.entries) do |arr, tag|
          arr.select{ |entry| entry.tags.any?(tag) }
        end
      end

      # Selects entries whose tags include one or more of the given tags
      def tagged_any(*args)
        tags = args.flatten.map(&:to_sym)
        results = tags.inject([]) do |arr, arg|
          arr << tagged(arg)
          arr
        end
        results.flatten.uniq
      end
      
      private

      def tagged(tag)
        Kiba::Extend.registry.entries.select{ |entry| entry.tags.any?(tag) }
      end

      def with_creator
        Kiba::Extend.registry.entries.select{ |entry| entry.creator }
      end
    end
  end
end
