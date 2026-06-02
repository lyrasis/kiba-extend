# frozen_string_literal: true

module Kiba
  module Extend
    module Command
      module Jobs
        class TaggedAnd
          def self.call(tags)
            result = Kiba::Extend::Registry::RegistryEntrySelector.new
              .tagged_all(tags)
            return [] if result.empty?

            result
          end
        end
      end
    end
  end
end
