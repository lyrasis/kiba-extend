# frozen_string_literal: true

require "diagram"
require "mermaid"

module Kiba
  module Extend
    module Registry
      # Mixin module for generating dependency tree diagram for entry
      # @since 7.0.0
      module Treeable
        include NodeLabelable

        # @return [Array<Symbol>]
        def parents
          files = creator.files
          [files[:source], files[:lookup]].compact
            .flatten
            .map do |file|
              next file if file.respond_to?(:key)

              Kiba::Extend.registry.resolve(file)
            end
        rescue NoMethodError
          []
        end

        # @return [Array<Symbol>]
        def ancestors
          result = [parents]
          until result.last.empty?
            result << traverse_up(result.last)
          end
          result.flatten.compact
        end

        # @return [Diagrams::FlowchartDiagram]
        def diagram
          Diagrams::FlowchartDiagram.new(nodes: nodes, edges: edges)
        end

        # @return [String]
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
