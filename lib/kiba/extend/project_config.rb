# frozen_string_literal: true

module Kiba
  module Extend
    # Project-specific configuration settings.
    #
    # All of these are optional. Ideally some of the project-specific
    #   settings from Kiba::Extend would be moved here.
    module ProjectConfig
      module_function

      extend Dry::Configurable

      # Configuration for making and reversing global replacements in your
      #   project via the {Transforms::Replace::GlobalReversible} and
      #   {Transforms::Replace::GlobalReverse} transforms.
      #
      # The most common use for this setting is removing formatting or
      #   special characters from data values to avoid them complicating
      #   the internal data processing. The `:replace` values are
      #   reversed to normal values in client-facing worksheets and reports,
      #   and in final data prepared for ingest
      # @note The `:replace` values should always be Strings that do not
      #   naturally appear in the data, otherwise the reverse replace will
      #   mess up the data.
      # @return [Hash{Regexp=>Hash}] This Hash's keys should be
      #   Regexps matching patterns in the original data that you wish
      #   to replace for the purposes of internal data processing.
      #   Each key's value is a Hash with Symbol keys `:replace` and
      #   `:reversed`. The value of each of those keys is a String.
      #   `:replace` is what the original Regexp match should be
      #   replaced with. `:reversed` is what the `:replace` value
      #   should be changed to when the replacements are reversed.
      # @example
      #   {
      #     /(?:\n|\r)/ => {replace: "%CR%", reversed: "\n"},
      #     /\t/ => {replace: "%TAB%", reversed: " "}
      #   }
      setting :global_reversible_replacements,
        reader: true,
        default: {}
    end
  end
end
