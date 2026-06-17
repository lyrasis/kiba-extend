# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      # Mixin module for generating dependency tree diagram for entry
      module Treeable
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

        private

        def traverse_up(elements)
          elements.map do |member|
            Kiba::Extend.registry
              .resolve(member.key)
              .parents
          end.flatten
            .compact
        end
      end
    end
  end
end
