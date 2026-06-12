# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Replace
        # Replaces all
        #   {Kiba::Extend::ProjectConfig.global_reversible_replacements}
        #   value[:replace] matches with the corresponding value[:reversed]
        #   value
        # @note Runs on **all** fields in the job where it is used.
        # @note Has no effect if
        #   {Kiba::Extend::ProjectConfig.global_reversible_replacements}
        #   is not populated
        # @see GlobalReversible
        # @example
        #   # Used in pipeline as:
        #   # transform Replace::GlobalReverse
        #   Kiba::Extend::ProjectConfig
        #     .config.global_reversible_replacements = {
        #       /(?:\n|\r)/ => {replace: "%CR%", reversed: "\n"},
        #       /\t/ => {replace: "%TAB%", reversed: " "},
        #       /  +/ => {replace: " ", reversed: " "}
        #     }
        #   xform = Replace::GlobalReverse.new
        #   input = [{
        #     ant: "a%CR%b",
        #     bat: nil,
        #     cow: nil,
        #     dog: "c%CR%d",
        #     eel: "e%TAB%f",
        #     fawn: "g o"
        #   }]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [{
        #     ant: "a\nb",
        #     bat: nil,
        #     cow: nil,
        #     dog: "c\nd",
        #     eel: "e f",
        #     fawn: "g o"
        #   }]
        #   expect(result).to eq(expected)
        #   Kiba::Extend::ProjectConfig.reset_config
        class GlobalReverse
          # @param omit_from_all_fields [Array<Symbol>] fields to omit from
          #   inclusion in "all" fields
          def initialize(omit_from_all_fields: [])
            @omit_from_all_fields = omit_from_all_fields
            @replacers =
              Kiba::Extend::ProjectConfig.global_reversible_replacements
                .values
                .reject { |config| config[:replace] == config[:reversed] }
                .map do |config|
                  Clean::RegexpFindReplaceFieldVals.new(
                    fields: :all,
                    omit_from_all_fields: omit_from_all_fields,
                    find: Regexp.new(config[:replace]),
                    replace: config[:reversed]
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
