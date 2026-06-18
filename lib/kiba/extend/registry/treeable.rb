# frozen_string_literal: true

require "diagram"
require "mermaid"

module Kiba
  module Extend
    module Registry
      # Mixin module for generating dependency tree diagram for entry
      module Treeable
        include NodeLabelable

        def parents
          files = creator.files
          [files[:source], files[:lookup]].compact
            .flatten
        rescue NoMethodError
          []
        end

        def ancestors
          result = [parents]
          until result.last.empty?
            result << traverse_up(result.last)
          end
          result.flatten.compact
        end

        def diagram
          Diagrams::FlowchartDiagram.new(nodes: nodes, edges: edges)
        end

        def mermaid = diagram.to_mermaid

        private

        def traverse_up(elements)
          elements.map do |member|
            Kiba::Extend.registry
              .resolve(member.key)
              .parents
          end.flatten
            .compact
        end

        def node_id = key

        def node = Diagrams::Elements::Node.new(id: node_id, label: node_label)

        def nodes = ancestors.uniq { |anc| anc.key }
          .map { |anc| anc.node } + [node]

        def edges = ancestors.map { |anc| anc.edge }
          .uniq
      end
    end
  end
end
