# frozen_string_literal: true

module Kiba
  module Extend
    module Command
      module Fcar
        # Wraps the creation of a formatted FCAR chute String from the
        #   Kiba::Extend::Fcar.chute config setting in a callable
        #   command class
        # @since 7.0.0
        # @return [String]
        class Chute
          def self.call
            Kiba::Extend::Fcar.chute
              .map do |mod, comment|
                formatted_comment = if comment.empty?
                  nil
                else
                  "  #{comment}"
                end
                [mod, formatted_comment].compact
                  .join("\n")
              end.join("\n")
          end
        end
      end
    end
  end
end
