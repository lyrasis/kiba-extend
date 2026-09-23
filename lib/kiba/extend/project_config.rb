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

      # @!group Data modification

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

      # @!endgroup

      # @!group Job tracking/handling

      # This setting supports protection against errors due to unexpected empty
      #   job output or missing tables.
      # @note It is NOT recommended that you set this manually. Generally, it
      #   should only be populated by project code or Kiba::Extend itself, in
      #   the course of running jobs or other commands.
      # @return [Array] jobs run which did not write any output
      setting :blank_jobs, default: %i[], reader: true

      # @!endgroup

      # @!group Mermaid job graph generation

      # Path to directory in which Mermaid .mmd files and generated
      #   image files will be stored. If not populated,
      # @return [String, NilClass]
      setting :graph_dir, reader: true, default: nil

      # @return [nil, String] path to project-specific JSON mermaid config, if
      #   defaults are not working for you
      # @example Use in project, assuming file is in top level of project repo
      #   Kiba::Extend::ProjectConfig.config.mermaid_config_path = File.join(
      #     Bundler.root, "mmd_config.json"
      #   )
      setting :mermaid_config_path,
        reader: true,
        default: nil

      # @!endgroup
    end
  end
end
