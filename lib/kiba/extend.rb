# frozen_string_literal: true

require "amazing_print"
require "active_support"
require "active_support/core_ext/object"
require "dry-configurable"
require "kiba"
require "kiba-common/sources/csv"
require "kiba-common/sources/enumerable"
require "kiba-common/destinations/csv"
require "kiba-common/destinations/lambda"
require "pry"
require "xxhash"
require "zeitwerk"

# The Kiba ETL framework for Ruby.
# `kiba-extend` extends only Kiba OSS. Kiba Pro features are not used.
#
# * [Main website](https://www.kiba-etl.org/)
# * [Github repo](https://github.com/thbar/kiba)
module Kiba
  # Handles:
  #
  # - auto-loading of the code
  # - extending `Kiba` with `Kiba::Extend::Jobs::JobSegmenter` so we
  #   can call `Kiba.job_segment`
  # - defining config settings, all of which can be overridden by
  #   project applications using `kiba-extend`
  #
  # Also defines some CSV converters:
  #
  # - `:stripextra` -- strips leading/trailing spaces, collapses
  #   multiple spaces, removes terminal commas, strips again
  # - `:nulltonil` -- replaces any values that are a literal string
  #   NULL with a nil value
  # - `:stripplus` -- strips leading/trailing spaces, collapses
  #   multiple spaces, removes terminal commas, strips again, removes
  #   "NULL" (i.e. literal string "NULL" becomes a `nilValue`
  #
  # Note that `:stripplus` combines the functionality of `:stripextra`
  #    and `:nulltonil`
  #
  # ## About pre-job task settings
  #
  # If configured properly, the pre-job task is run when a job is run
  #   via Thor invocation. This includes `run:job`, `run:jobs`, and
  #   `jobs:tagged -r tagvalue`. The task is run once when the Thor
  #   task is invoked.
  module Extend
    module_function

    extend Dry::Configurable

    # @return [String] path to this application's data directory (used
    #   internally by transforms and utils), and not specific to a project
    setting :ke_dir,
      reader: true,
      constructor: ->(value) do
        Gem.loaded_specs["kiba-extend"].full_gem_path
      end

    def loader
      @loader ||= setup_loader
    end

    private def setup_loader
      @loader = Zeitwerk::Loader.new
      @loader.push_dir(
        File.join(ke_dir, "lib", "kiba", "extend"),
        namespace: Kiba::Extend
      )
      @loader.inflector.inflect(
        "normalize_for_id" => "NormalizeForID",
        "convert_to_id" => "ConvertToID",
        "version" => "VERSION",
        "csv" => "CSV"
      )
      @loader.enable_reloading
      @loader.setup
      @loader.eager_load
      @loader
    end

    def reload!
      @loader.reload
    end

    # Ruby modules that serve as namespaces under which config
    #   modules for a project are nested.
    # @since 4.0.0
    # @note You must set this from
    #   an individual project if you wish to use the
    #   {Kiba::Extend::Mixins::IterativeCleanup} mixin.
    # @return [Array<Module>]
    setting :config_namespaces, default: [], reader: true

    # Default options used for CSV sources/destinations
    #
    # @return [Hash]
    setting :csvopts,
      default: {headers: true, header_converters: %i[symbol downcase]},
      reader: true

    # Default settings for Lambda destination
    # @return [Hash]
    setting :lambdaopts, default: {on_write: ->(r) {
                                               accumulator << r
                                             }}, reader: true

    # @return [String]
    # Default delimiter for splitting/joining values in multi-valued fields.
    #
    # ~~~
    # 'a|b'.split(Kiba::Extend.delim) => ['a', 'b']
    # ~~~
    setting :delim, default: "|", reader: true

    # Default subgrouping delimiter for splitting/joining values in multi-valued
    #   fields
    #
    # ~~~
    # orig = 'a^^y|b^^z'
    # delim_split = orig.split(delim)
    # sgdelim_split = delim_split.map{ |val| val.split(sgdelim) }
    # sgdelim_split => [['a', 'y'], ['b', 'z']]
    # ~~~
    #
    # @return [String]
    setting :sgdelim, default: "^^", reader: true

    # Default string to be treated as though it were a null/empty value.
    #
    # @return [String]
    setting :nullvalue, default: "%NULLVALUE%", reader: true

    # Used to join nested namespaces and registered keys in
    #   FileRegistry. With namespace 'ns' and registered key 'foo':
    #   'ns\__foo'. With parent namespace 'ns', child namespace
    #   'child', and registered key 'foo': 'ns\__child\__foo'
    #
    # @return [String]
    setting :registry_namespace_separator, default: "__", reader: true

    # Default source class for jobs. Must meet implementation criteria
    # in [Kiba
    # wiki](https://github.com/thbar/kiba/wiki/Implementing-ETL-sources)
    #
    # @return [Class]
    setting :source, constructor: proc {
                                    Kiba::Extend::Sources::CSV
                                  }, reader: true

    # Default destination class for jobs. Must meet implementation
    # criteria in [Kiba
    # wiki](https://github.com/thbar/kiba/wiki/Implementing-ETL-destinations)
    #
    # @return [Class]
    setting :destination, constructor: proc {
                                         Kiba::Extend::Destinations::CSV
                                       }, reader: true

    # Prefix for warnings from the ETL
    #
    # @return [String]
    setting :warning_label, default: "KIBA WARNING", reader: true

    # A customized
    #   [dry-container](https://dry-rb.org/gems/dry-container/main/)
    #   for registering and resolving jobs
    #
    # @return [Kiba::Extend::Registry::FileRegistry]
    setting :registry,
      constructor: proc { Kiba::Extend::Registry::FileRegistry.new },
      reader: true

    # The job definition module method expected to be present if you
    #   [define a registry entry hash creator as a
    #   Module](https://lyrasis.github.io/kiba-extend/file.file_registry_entry.html#module-creator-example-since-2-7-2)
    #
    # @return [Symbol]
    setting :default_job_method_name, default: :job, reader: true

    # Whether to use Kiba::Extend's pre-job task functionality. The
    #   default is `false` for backward compatibility, as existing
    #   projects may not have the required settings configured.
    #
    # @return [Boolean]
    setting :pre_job_task_run, default: false, reader: true

    # Full path to directory to which files will be moved if
    #   `pre_job_task_action == :backup`. The directory will be
    #   created if it does not exist.
    #
    # @return [String]
    setting :pre_job_task_backup_dir, default: nil, reader: true

    # Full paths to directories that will be affected by the specified pre-task
    #   action
    # @return [Array<String>]
    setting :pre_job_task_directories, default: [], reader: true

    # Controls what happens when pre-job task is run
    #
    # - :backup - Moves all existing files in specified directories to backup
    #   directory created in your `:datadir`
    # - :nuke - Deletes all existing files in specified directories
    #    when a job is run. **Make sure you only specify directories
    #    that contain derived/generated files!**
    #
    # @return [:backup, :nuke]
    setting :pre_job_task_action, default: :backup, reader: true

    # Controls whether pre-job task is run
    #
    # - :job - runs pre-job task specified above whenever you invoke
    #   `thor run:job ...`. All dependency jobs required for the
    #   invoked job will be run. This mode is recommended during
    #   development when you want any change in the dependency chain
    #   to get picked up.
    # - any other value - only regenerates missing dependency files.
    #   Useful when your data is really big and/or your jobs are more
    #   stable
    #
    # @return [:job, nil, anyValue]
    setting :pre_job_task_mode, default: :job, reader: true

    # Whether to output results to STDOUT for debugging
    #
    # @return [Boolean]
    setting :job_show_me, default: false, reader: true

    # Whether to have computer audibly say something when job is complete
    #
    # @return [Boolean]
    setting :job_tell_me, default: false, reader: true

    # How much output about jobs to output to STDOUT
    #
    # - :debug - tells you A LOT - helpful when developing pipelines and
    #   debugging
    # - :normal - reports what is running, from where, and the results
    # - :minimal - bare minimum
    #
    # @return [:debug, :normal, :minimal]
    setting :job_verbosity, default: :normal, reader: true

    # List of config modules in project namespaces set in {config_namespaces}
    #   setting
    #
    # @since 4.0.0
    # @return [Array<Module>]
    def project_configs
      config_namespaces.map { |ns| get_config_mods(ns, ns.constants) }
        .flatten
        .select { |obj| obj.is_a?(Module) && obj.respond_to?(:config) }
    end

    # @param ns [Module]
    # @param constants [Array<Symbol>]
    # @since 4.0.0
    # @return [Array<Module>]
    def get_config_mods(ns, constants)
      constants.map { |const| ns.const_get(const) }
    end
    private_class_method :get_config_mods

    # Strips, collapses multiple spaces, removes terminal commas, strips again
    # removes "NULL"/treats as nilValue
    CSV::Converters[:stripplus] = lambda { |s|
      begin
        if s.nil?
          nil
        elsif s == "NULL"
          nil
        else
          s.strip
            .gsub(/  +/, " ")
            .sub(/,$/, "")
            .sub(/^%(LINEBREAK|CRLF)%/, "")
            .sub(/%(LINEBREAK|CRLF)%$/, "")
            .strip
        end
      rescue ArgumentError
        s
      end
    }

    # Strips, collapses multiple spaces, removes terminal commas, strips again
    CSV::Converters[:stripextra] = lambda { |s|
      begin
        if s.nil?
          nil
        else
          s.strip
            .gsub(/  +/, " ")
            .sub(/,$/, "")
            .sub(/^%(LINEBREAK|CRLF)%/, "")
            .sub(/%(LINEBREAK|CRLF)%$/, "")
            .strip
        end
      rescue ArgumentError
        s
      end
    }

    # replaces any values that are a literal string NULL with a nil value
    CSV::Converters[:nulltonil] = lambda { |s|
      begin
        if s == "NULL"
          nil
        else
          s
        end
      rescue ArgumentError
        s
      end
    }
  end
end

Kiba::Extend.loader
# So we can call Kiba.job_segment
Kiba.extend(Kiba::Extend::Jobs::JobSegmenter)
