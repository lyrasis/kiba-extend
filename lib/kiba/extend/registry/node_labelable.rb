# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      # Mixin module for generating Node label for dependency graph
      # @since 7.0.0
      module NodeLabelable
        # @return [String]
        def node_qualification
          return "#{node_id} (supplied)" if supplied
          return "#{node_id} (dynamic)" if dynamic_source

          node_id
        end

        # @return [String]
        def node_label
          return node_qualification if desc.empty?

          "#{node_qualification}\n#{desc}"
        end
      end
    end
  end
end
