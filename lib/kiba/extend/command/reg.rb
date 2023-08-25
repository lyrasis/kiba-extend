# frozen_string_literal: true

module Kiba
  module Extend
    module Command
      module Reg
        module_function

        def list
          puts Kiba::Extend::Registry::RegistryList.new
        end

        def tags
          Kiba::Extend.registry.entries.map(&:tags)
            .compact
            .reject(&:empty?)
            .flatten
            .uniq
            .sort
        end

        def validate
          Kiba::Extend::Registry::RegistryValidator.new.report
        end
      end
    end
  end
end
