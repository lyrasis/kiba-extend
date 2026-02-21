# frozen_string_literal: true

module Kiba
  module Extend
    module JobTest
      class TestPrepper
        # @param nodes [Array<Psych::Nodes::Mapping>]
        def initialize(nodes)
          @yml = nodes.children
          @config = {srcline: yml.first.start_line + 1}
        end

        # @return [Hash]
        def call
          add_to_config until yml.empty?
          config
        end

        private

        attr_reader :yml, :config

        def add_to_config
          config[yml.shift.value.to_sym] = yml.shift.value
        end
      end
    end
  end
end
