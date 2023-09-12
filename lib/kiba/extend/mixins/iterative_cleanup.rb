# frozen_string_literal: true

module Kiba
  module Extend
    module Mixins
      # Mixin module for setting up iterative cleanup based on a source table.
      #
      # @since 4.0.0
      #
      # "Iterative cleanup" means the client may provide the worksheet more
      #   than once, or that you may need to produce a fresh worksheet for
      #   the client after a new database export is provided.
      #
      # Your project must follow some setup/configuration conventions
      #   in order to use this mixin:
      #
      # - Each cleanup process must be configured in its own config module.
      # - A config module is a Ruby module that responds to `:config`.
      #
      # Refer to todo:link Kiba::Tms::AltNumsForObjTypeCleanup as an
      #   example config module extending this mixin module in a
      #   simple way. See todo:link Kiba::Tms::PlacesCleanupInitial
      #   for a more complex usage with default overrides and custom
      #   pre/post transforms.
      #
      # ## Implementation details
      #
      # ### Define before extending this module
      #
      # These can be defined as Dry::Configurable settings or as
      #   public methods. The section below lists the method/setting
      #   name the extending module should respond to, each preceded
      #   by its YARD signature.
      #
      # ```
      # # @return [Symbol] registry entry job key for the job whose output
      # #   will be used as the base for generating the cleanup worksheet.
      # #   Iterations of cleanup will be layered over this output in the
      # #   auto-generated. **NOTE: This job's output should include a field
      # #   which combines/identifies the original values that may be
      # #   affected by the cleanup process. The default expectation is that
      # #   this field is named :fingerprint, but this can be overridden by
      # #   defining a custom `orig_values_identifier` method in the
      # #   extending module after extension. This field is used as a
      # #   matchpoint for merging cleaned up data back into the migration,
      # #   and identifying whether a given value in subsequent worksheet
      # #   iterations has been previously included in a worksheet**
      # # base_job
      # #
      # # @return [Array<Symbol>] fields included in the fingerprint value
      # # fingerprint_fields
      # ```
      #
      # ### Then, extend this module
      #
      # `extend Kiba::Extend::Mixins::IterativeCleanup`
      #
      # ### Optional settings/methods in extending module
      #
      # Default values for the following methods are defined in this mixin
      #   module. If you want to override the values, define these methods
      #   in your config module after extending this module.
      #
      # - {cleanup_base_name}
      # - {orig_values_identifier}
      # - {job_tags}
      # - {worksheet_add_fields}
      # - {worksheet_field_order}
      # - {collate_fields}
      # - {collation_delim}
      # - {clean_fingerprint_flag_ignore_fields}
      # - {final_lookup_on_field}
      #
      # ## What extending this module does
      #
      # ### Defines settings in the extending config module
      #
      # These are empty settings with constructors that will use the
      #   values in a client-specific project config file to build the
      #   data expected for cleanup processing
      #
      # - **:provided_worksheets** - Array of filenames of cleanup
      #   worksheets provided to the client. Files should be listed
      #   oldest-to-newest. Assumes files are in the `to_client`
      #   subdirectory of the migration base directory. **Define actual
      #   values in client config file.**
      ## - **:returned_files** - Array of filenames of completed worksheets
      #   returned by client. Files should be listed oldest-to-newest.
      #   Assumes files are in the `supplied` subdirectory of the migration
      #   base directory. **Define actual values in client config file.**
      #
      # ### Defines methods in the extending config module
      #
      # See method documentation inline below.
      #
      # ### Prepares registry entries for iterative cleanup jobs
      #
      # When the project application loads, the method that registers
      #   the project's registry entries calls
      #   {Kiba::Extend::Utils::IterativeCleanupJobRegistrar}. This
      #   util class calls the {register_cleanup_jobs} method of each
      #   config module extending this module, adding the cleanup jobs
      #   to the registry dynamically.
      #
      # The jobs themselves (i.e. the sources, lookups, transforms)
      #   are defined in
      #   {Kiba::Extend::Mixins::IterativeCleanup::Jobs}. See that
      #   module's documentation for how to set up custom pre/post
      #   transforms to customize specific cleanup routines.
      module IterativeCleanup
        def self.extended(mod)
          check_required_settings(mod)
          define_provided_worksheets_setting(mod)
          define_returned_files_setting(mod)
        end

        # OVERRIDEABLE PUBLIC METHODS

        # Used as the namespace for auto-generated registry entries and the
        #   base for output file names. DEFAULT VALUE: the name of
        #   the extending module, converted to snake case.
        #
        # @note Optional: override in extending module after extending
        #
        # @return [String]
        def cleanup_base_name
          name.split("::")[-1]
            .gsub(/([A-Z])/, '_\1')
            .delete_prefix("_")
            .downcase
        end

        # Field in base job that combines/identifies the original
        #   field values entering the cleanup process. This field is
        #   used as a matchpoint for merging cleaned up data back into
        #   the migration, and identifying whether a given value in
        #   subsequent worksheet iterations has been previously
        #   included in a worksheet. DEFAULT VALUE: `:fingerprint`
        #
        # @note Optional: override in extending module after extending
        #
        # @return [Symbol]
        def orig_values_identifier
          :fingerprint
        end

        # Tags assigned to all jobs generated by IterativeCleanup for this
        #   module. DEFAULT VALUE: `[]` (empty array)
        #
        # @note Optional: override in extending module after extending
        #
        # @return [Array<Symbol>]
        def job_tags
          []
        end

        # Nil/empty fields to be added to worksheet. Note: values from these
        #   fields are retained from returned cleanup worksheets if these fields
        #   are included in `fingerprint_fields`. DEFAULT VALUE: `[]`
        #
        # @note Optional: override in extending module after extending
        #
        # @return [Array<Symbol>]
        def worksheet_add_fields
          []
        end

        # Order of fields (in worksheet output). Will be used to set
        #   destination special options/initial headers on the
        #   worksheet job. DEFAULT VALUE: `[]`
        #
        # @note Optional: override in extending module after extending
        #
        # @return [Array<Symbol>]
        def worksheet_field_order
          []
        end

        # Fields from base_job_cleaned that will be deleted in
        #   cleaned_uniq, and then merged back into the deduplicated
        #   data from base_job_cleaned. I.e., fields whose values will
        #   be collated into multivalued fields on the deduplicated
        #   values. DEFAULT VALUE: `[]`
        #
        # @note Optional: override in extending module after extending
        #
        # @return [Array<:fingerprint>]
        def collate_fields
          []
        end

        # Delimiting string used to join collated-on-deduplication
        #   values. Should be distinct from normal application
        #   delimiters since the field values being joined/split may
        #   contain the normal application delimiters. DEFAULT VALUE: `"////"`
        #
        # @note Optional: override in extending module after extending
        #
        # @return [String]
        def collation_delim
          "////"
        end

        # Field(s) included in `fingerprint_fields` setting that
        #   should be ignored when identifying changed/corrected
        #   values in returned worksheets. If a Symbol or Array of
        #   Symbols is given, these are passed as the value of
        #   `ignore_fields` when
        #   {Kiba::Extend::Transforms::Fingerprint::FlagChanged} is
        #   called.  DEFAULT VALUE: `nil`
        #
        # This is included because of two situations that I've run into:
        #
        # - I accidentally included a field I shouldn't have in the
        #   fingerprint and sent a worksheet to the client. For
        #   example, maybe I put `:client_cleanup_process_notes` in
        #   the `worksheet_add_fields` setting, told the client these
        #   notes are for their use only and will not be considered
        #   "corrections" or merged into the migration or future
        #   cleanup iterations, but I forgot to subtract this field
        #   from my `fingerprint_fields` setting.
        # - I purposefully included a field (e.g. `:rowid`) present in
        #   my `base_job` in `fingerprint_fields` to ensure unique
        #   matchpoints, but didn't want to include that field in the
        #   client worksheet. If I don't ignore this field in flagging
        #   changes, `:rowid` in all returned worksheets is `nil`,
        #   which does not match the fingerprinted `:rowid` value, and
        #   thus **every row** is a changed row.
        #
        # @note Optional: override in extending module after extending
        #
        # @return [nil, Symbol, Array<Symbol>]
        def clean_fingerprint_flag_ignore_fields
          nil
        end

        # Will be used to set the `lookup_on` field in job registry
        #   hash for `cleanup_base_name__final`, for merging
        #   cleaned-up data back into the rest of your migration.
        #   DEFAULT VALUE: value of orig_values_identifier
        #
        # @note Optional: override in extending module after extending
        #
        # @return [Symbol]
        def final_lookup_on_field
          orig_values_identifier
        end

        # DO NOT OVERRIDE REMAINING METHODS

        # @return [Array<Symbol>] supplied registry entry job keys
        #   corresponding to returned cleanup files
        #
        # @note Do not override
        def returned_file_jobs
          returned_files.map.with_index do |filename, idx|
            "#{cleanup_base_name}__file_returned_#{idx}".to_sym
          end
        end

        # @return [Boolean]
        #
        # @note Do not override
        def cleanup_done?
          true unless returned_files.empty?
        end
        alias_method :cleanup_done, :cleanup_done?

        # @return [Boolean]
        #
        # @note Do not override
        def worksheet_sent_not_done?
          true if !cleanup_done? && !provided_worksheets.empty?
        end

        # Ensures that orig_values_identifier is always included in collated
        #   fields
        #
        # @note Override at your peril
        #
        # @return [Array<Symbol>]
        def all_collate_fields
          [collate_fields, orig_values_identifier].flatten.uniq
        end

        # @return [Symbol] the registry entry job key for the base job
        #   with cleanup merged in
        #
        # @note Do not override
        def base_job_cleaned_job_key
          "#{cleanup_base_name}__base_job_cleaned".to_sym
        end

        # @return [Symbol] the registry entry job key for the job that
        #   deduplicates the clean base job data
        #
        # @note Do not override
        def cleaned_uniq_job_key
          "#{cleanup_base_name}__cleaned_uniq".to_sym
        end

        # @return [Symbol] the registry entry job key for the worksheet prep job
        #
        # @note Do not override
        def worksheet_job_key
          "#{cleanup_base_name}__worksheet".to_sym
        end

        # @return [Symbol] the registry entry job key for the compiled
        # corrections job
        #
        # @note Do not override
        def returned_compiled_job_key
          "#{cleanup_base_name}__returned_compiled".to_sym
        end

        # @return [Symbol] the registry entry job key for the compiled
        # corrections job
        #
        # @note Do not override
        def corrections_job_key
          "#{cleanup_base_name}__corrections".to_sym
        end

        def final_job_key
          "#{cleanup_base_name}__final".to_sym
        end

        # Appends "s" to module's `orig_values_identifier`. Used to
        #   manage joining, collating, and splitting/exploding on this
        #   value, while clarifying that any collated field in output
        #   is collated (not expected to be a single value.
        def collated_orig_values_id_field
          "#{orig_values_identifier}s".to_sym
        end

        def self.check_required_settings(mod)
          %i[base_job fingerprint_fields].each do |setting|
            unless mod.respond_to?(setting)
              raise Kiba::Extend::IterativeCleanupSettingUndefinedError, setting
            end
          end
        end
        private_class_method :check_required_settings

        def self.datadir(mod)
          dir = nil
          parents = mod.module_parents

          until dir || parents.empty?
            parent = parents.shift
            dir = parent.datadir if parent.respond_to?(:datadir)
          end

          raise Kiba::Extend::ProjectSettingUndefinedError, :datadir unless dir

          dir
        end

        def self.define_provided_worksheets_setting(mod)
          provided_worksheets = <<~CODE
            # Filenames of cleanup worksheets provided to the client. Should be
            #   ordered oldest-to-newest. Assumes files are in the `to_client`
            #   subdirectory of the migration base directory
            #
            # @return Array<String>
            setting :provided_worksheets,
              default: [],
              reader: true,
              constructor: proc { |value|
                value.map do |filename|
                  File.join(Kiba::Extend::Mixins::IterativeCleanup.datadir(mod),
                    "to_client", filename)
                end
              }
          CODE
          mod.module_eval(provided_worksheets, __FILE__, __LINE__)
        end
        private_class_method :define_provided_worksheets_setting

        def self.define_returned_files_setting(mod)
          returned_files = <<~CODE
            # Filenames of cleanup worksheets returned by the client. Should be
            #   ordered oldest-to-newest. Assumes files are in the `supplied`
            #   subdirectory of the migration base directory
            #
            # @return Array<String>
            setting :returned_files,
              default: [],
              reader: true,
              constructor: proc { |value|
                value.map do |filename|
                  File.join(Kiba::Extend::Mixins::IterativeCleanup.datadir(mod),
                    "supplied", filename)
                end
              }
          CODE
          mod.module_eval(returned_files, __FILE__, __LINE__)
        end
        private_class_method :define_returned_files_setting

        def register_cleanup_jobs
          ns = build_namespace
          Kiba::Extend.registry.import(ns)
        end

        def build_namespace
          bind = binding

          Dry::Container::Namespace.new(cleanup_base_name) do
            mod = bind.receiver
            register mod.send(:job_name, mod.send(:base_job_cleaned_job_key)),
              mod.send(:base_job_cleaned_job_hash, mod)
            register mod.send(:job_name, mod.send(:cleaned_uniq_job_key)),
              mod.send(:cleaned_uniq_job_hash, mod)
            register mod.send(:job_name, mod.send(:worksheet_job_key)),
              mod.send(:worksheet_job_hash, mod)
            if mod.cleanup_done?
              returned = mod.send(:returned_files)
              returned_jobs = mod.send(:returned_file_jobs)
                .map { |job| mod.send(:job_name, job) }
              returned.each_with_index do |file, idx|
                register returned_jobs[idx], {
                  path: file,
                  supplied: true,
                  tags: mod.send(:job_tags)
                }
              end
              register mod.send(
                :job_name,
                mod.send(:returned_compiled_job_key)
              ),
                mod.send(:returned_compiled_job_hash, mod)
              register mod.send(:job_name, mod.send(:corrections_job_key)),
                mod.send(:corrections_job_hash, mod)
            end
            register mod.send(:job_name, mod.send(:final_job_key)),
              mod.send(:final_job_hash, mod)
          end
        end
        private :build_namespace

        def job_name(full_job_key)
          full_job_key.to_s
            .delete_prefix("#{cleanup_base_name}__")
            .to_sym
        end
        private :job_name

        def base_job_cleaned_job_hash(mod)
          {
            path: File.join(Kiba::Extend::Mixins::IterativeCleanup.datadir(mod),
              "working", "#{mod.cleanup_base_name}_base_job_cleaned.csv"),
            creator: {
              callee:
              Kiba::Extend::Mixins::IterativeCleanup::Jobs::BaseJobCleaned,
              args: {mod: mod}
            },
            tags: mod.job_tags,
            lookup_on: :clean_fingerprint
          }
        end
        private :base_job_cleaned_job_hash

        def cleaned_uniq_job_hash(mod)
          {
            path: File.join(Kiba::Extend::Mixins::IterativeCleanup.datadir(mod),
              "working", "#{mod.cleanup_base_name}_cleaned_uniq.csv"),
            creator: {
              callee: Kiba::Extend::Mixins::IterativeCleanup::Jobs::CleanedUniq,
              args: {mod: mod}
            },
            tags: mod.job_tags
          }
        end
        private :cleaned_uniq_job_hash

        def worksheet_job_hash(mod)
          {
            path: File.join(Kiba::Extend::Mixins::IterativeCleanup.datadir(mod),
              "to_client", "#{mod.cleanup_base_name}_worksheet.csv"),
            creator: {
              callee: Kiba::Extend::Mixins::IterativeCleanup::Jobs::Worksheet,
              args: {mod: mod}
            },
            tags: mod.job_tags,
            dest_special_opts: {initial_headers: mod.worksheet_field_order}
          }
        end
        private :worksheet_job_hash

        def returned_compiled_job_hash(mod)
          {
            path: File.join(Kiba::Extend::Mixins::IterativeCleanup.datadir(mod),
              "working", "#{mod.cleanup_base_name}_returned_compiled.csv"),
            creator: {
              callee:
              Kiba::Extend::Mixins::IterativeCleanup::Jobs::ReturnedCompiled,
              args: {mod: mod}
            },
            tags: mod.job_tags
          }
        end
        private :returned_compiled_job_hash

        def corrections_job_hash(mod)
          {
            path: File.join(Kiba::Extend::Mixins::IterativeCleanup.datadir(mod),
              "working", "#{mod.cleanup_base_name}_corrections.csv"),
            creator: {
              callee: Kiba::Extend::Mixins::IterativeCleanup::Jobs::Corrections,
              args: {mod: mod}
            },
            tags: mod.job_tags,
            lookup_on: mod.orig_values_identifier
          }
        end
        private :corrections_job_hash

        def final_job_hash(mod)
          {
            path: File.join(Kiba::Extend::Mixins::IterativeCleanup.datadir(mod),
              "working", "#{mod.cleanup_base_name}_final.csv"),
            creator: {
              callee:
              Kiba::Extend::Mixins::IterativeCleanup::Jobs::Final,
              args: {mod: mod}
            },
            tags: mod.job_tags,
            lookup_on: mod.final_lookup_on_field
          }
        end
        private :final_job_hash
      end
    end
  end
end
