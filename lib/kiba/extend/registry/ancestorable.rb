# frozen_string_literal: true

require "diagram"

module Kiba
  module Extend
    module Registry
      # Mixin module for getting Node and Edge properties from RegisteredSource
      #   and RegisteredLookup objects
      module Ancestorable
        def node
          Diagrams::Elements::Node.new(id: node_id, label: node_label)
        end

        def node_id = key.to_s

        def node_label
          return node_id unless supplied

          "#{node_id} (supplied)"
        end

        def edge
          Diagrams::Elements::Edge.new(
            source_id: edge_source_id,
            target_id: edge_target_id,
            label: edge_label
          )
        end

        def edge_source_id = node_id

        def edge_target_id = for_job.to_s

        def edge_label
          return "" if source?

          "lookup on :#{lookup_on}"
        end

        def source? = is_a?(RegisteredSource)
      end
    end
  end
end
