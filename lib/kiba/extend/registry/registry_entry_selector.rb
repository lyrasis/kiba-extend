# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      # Used in Thor tasks in project application to identify
      #   particular files/jobs to run or display information about
      class RegistryEntrySelector
        # @param cstr [String] stringified class name
        # @return [Array<FileRegistryEntry>] created by a given class
        def created_by_class(cstr)
          with_creator.select { |entry| entry.creator.mod.to_s[cstr] }
        end

        # Registry entry or entries created by a given method
        # @param mstr [String] stringified method name
        # @return [Array<FileRegistryEntry>]
        def created_by_method(mstr)
          matcher = "#<Method: #{mstr}("
          with_creator.select { |entry| entry.creator.to_s[matcher] }
        end

        # Selects entries whose tags include all given tags
        # @param args [Array<Symbol>]
        # @return [Array<FileRegistryEntry>]
        def tagged_all(*args)
          tags = args.flatten.map(&:to_sym)
          tags.inject(Kiba::Extend.registry.entry_objs) do |arr, tag|
            arr.select { |entry| entry.tags.any?(tag) }
          end
        end

        # Selects entries whose tags include one or more of the given tags
        # @param args [Array<Symbol>]
        # @return [Array<FileRegistryEntry>]
        def tagged_any(*args)
          args.flatten
            .map { |tag| tagged(tag.to_sym) }
            .flatten
            .uniq
        end

        private

        def tagged(tag)
          Kiba::Extend.registry
            .entry_objs
            .select { |entry| entry.tags.any?(tag) }
        end

        def with_creator
          Kiba::Extend.registry
            .entry_objs
            .reject { |entry| !entry.creator }
        end
      end
    end
  end
end
