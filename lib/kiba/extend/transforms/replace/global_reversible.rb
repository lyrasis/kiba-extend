# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Replace
        # Replaces all
        #   {Kiba::Extend::ProjectConfig.global_reversible_replacements}
        #   key matches with the corresponding `:replace` value.
        # @note Runs on **all** fields in the job where it is used.
        # @note Has no effect if
        #   {Kiba::Extend::ProjectConfig.global_reversible_replacements}
        #   is not populated
        # @see GlobalReverse
        # @example
        #   # Used in pipeline as:
        #   # transform Replace::GlobalReversible
        #   Kiba::Extend::ProjectConfig
        #     .config.global_reversible_replacements = {
        #       /(?:\n|\r)/ => {replace: "%CR%", reversed: "\n"},
        #       /\t/ => {replace: "%TAB%", reversed: " "},
        #       /  +/ => {replace: " ", reversed: " "}
        #     }
        #   xform = Replace::GlobalReversible.new
        #   input = [{
        #     ant: "a\nb",
        #     bat: nil,
        #     cow: "",
        #     dog: "c\rd",
        #     eel: "e\tf",
        #     fawn: "g    o"
        #   }]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [{
        #     ant: "a%CR%b",
        #     bat: nil,
        #     cow: nil,
        #     dog: "c%CR%d",
        #     eel: "e%TAB%f",
        #     fawn: "g o"
        #   }]
        #   expect(result).to eq(expected)
        #   Kiba::Extend::ProjectConfig.reset_config
        class GlobalReversible
          def initialize
            @replacers =
              Kiba::Extend::ProjectConfig.global_reversible_replacements
                .map do |pattern, config|
                  Clean::RegexpFindReplaceFieldVals.new(
                    fields: :all,
                    find: pattern,
                    replace: config[:replace]
                  )
                end
          end

          def process(row)
            replacers.each { |replacer| replacer.process(row) }
            row
          end

          private

          attr_reader :replacers
        end
      end
    end
  end
end
