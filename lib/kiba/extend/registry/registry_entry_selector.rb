# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      # Used in Rake tasks in project application to identify particular files/jobs
      #   to run or display information about
      class RegistryEntrySelector
        # Registry entries created by a given class
        # @param cstr [String] stringified class name
        # @return [Array<FileRegistryEntry>]
        def created_by_class(cstr)
          with_creator.select { |entry| entry.creator.owner.to_s[cstr] }
        end

        # Registry entry or entries created by a given method
        # @param mstr [String] stringified method name
        # @return [Array<FileRegistryEntry>]
        def created_by_method(mstr)
          matcher = "#<Method: #{mstr}("
          with_creator.select { |entry|
          binding.pry if mstr.end_with?('.csv_to_hash')
            entry.creator.to_s[matcher] }
        end

        # Selects entries whose tags include all given tags
        # @param args [Array<Symbol>]
        # @return [Array<FileRegistryEntry>]
        def tagged_all(*args)
          tags = args.flatten.map(&:to_sym)
          tags.inject(Kiba::Extend.registry.entries) do |arr, tag|
            arr.select { |entry| entry.tags.any?(tag) }
          end
        end

        # Selects entries whose tags include one or more of the given tags
        # @param args [Array<Symbol>]
        # @return [Array<FileRegistryEntry>]
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
          Kiba::Extend.registry.entries.select { |entry| entry.tags.any?(tag) }
        end

        def with_creator
          Kiba::Extend.registry.entries.select { |entry| entry.creator }
        end
      end
    end
  end
end