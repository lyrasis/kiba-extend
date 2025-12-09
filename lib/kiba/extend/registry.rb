# frozen_string_literal: true

module Kiba
  module Extend
    # Support for defining project-specific file registry
    #
    # This DRYs up the process of setting up job configs (i.e. the
    #   source, lookup, and destination files for that job.
    #
    # This also allows for automated calling of dependencies instead
    #   of having to redundantly hard code them for every job. If the
    #   file(s) needed as sources or lookups do not exist, their
    #   creator jobs will be run to create them.
    #
    # @since 2.2.0
    module Registry
      module_function

      # @param jobkey [Symbol] registry entry key for job with namespace
      # @return [Kiba::Extend::Registry::FileRegistryEntry]
      def entry_for(jobkey)
        entry = Kiba::Extend.registry.resolve(jobkey)
        return entry if entry.respond_to?(:creator)

        Kiba::Extend::Registry::FileRegistryEntry.new(jobkey, entry)
      rescue(Dry::Container::KeyError) => err
        raise Kiba::Extend::JobNotRegisteredError.new(err, "Registry.entry_for")
      end
    end
  end
end
