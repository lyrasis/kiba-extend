# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      # Mixin module for generating Node label for dependency graph
      module NodeLabelable
        def node_label
          return "#{node_id} (supplied)" if supplied
          return node_id if desc.empty?

          "#{node_id}\n#{desc}"
        end
      end
    end
  end
end
