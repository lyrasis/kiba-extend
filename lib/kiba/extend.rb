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
  # rubocop:todo Layout/LineLength
  # - extending `Kiba` with `Kiba::Extend::Jobs::JobSegmenter` so we can call `Kiba.job_segment`
  # rubocop:enable Layout/LineLength
  # rubocop:todo Layout/LineLength
  # - defining config settings, all of which can be overridden by project applications using
  # rubocop:enable Layout/LineLength
  #   `kiba-extend`
  #
  # Also defines some CSV converters:
  #
  # rubocop:todo Layout/LineLength
  # - `:stripextra` -- strips leading/trailing spaces, collapses multiple spaces, removes terminal commas,
  # rubocop:enable Layout/LineLength
  #   strips again
  # rubocop:todo Layout/LineLength
  # - `:nulltonil` -- replaces any values that are a literal string NULL with a nil value
  # rubocop:enable Layout/LineLength
  # rubocop:todo Layout/LineLength
  # - `:stripplus` -- strips leading/trailing spaces, collapses multiple spaces, removes terminal commas,
  # rubocop:enable Layout/LineLength
  # rubocop:todo Layout/LineLength
  #   strips again, removes "NULL" (i.e. literal string "NULL" becomes a `nilValue`
  # rubocop:enable Layout/LineLength
  #
  # rubocop:todo Layout/LineLength
  # Note that `:stripplus` combines the functionality of `:stripextra` and `:nulltonil`
  # rubocop:enable Layout/LineLength
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

    # @return [Hash] default options used for CSV sources/destinations
    setting :csvopts,
      # rubocop:todo Layout/LineLength
      default: {headers: true, header_converters: %i[symbol downcase]}, reader: true
    # rubocop:enable Layout/LineLength

    # @return [Hash] default settings for Lambda destination
    setting :lambdaopts, default: {on_write: ->(r) {
                                               accumulator << r
                                             }}, reader: true

    # @return [String]
    # Default delimiter for splitting/joining values in multi-valued fields.
    #
    # ```
    # 'a|b'.split(Kiba::Extend.delim) => ['a', 'b']
    # ```
    setting :delim, default: "|", reader: true

    # @return [String]
    # rubocop:todo Layout/LineLength
    # Default subgrouping delimiter for splitting/joining values in multi-valued fields
    # rubocop:enable Layout/LineLength
    #
    # ```
    # orig = 'a^^y|b^^z'
    # delim_split = orig.split(delim)
    # sgdelim_split = delim_split.map{ |val| val.split(sgdelim) }
    # sgdelim_split => [['a', 'y'], ['b', 'z']]
    # ```
    setting :sgdelim, default: "^^", reader: true

    # rubocop:todo Layout/LineLength
    # @return [String] default string to be treated as though it were a null/empty value.
    # rubocop:enable Layout/LineLength
    setting :nullvalue, default: "%NULLVALUE%", reader: true

    # @return [String]
    # rubocop:todo Layout/LineLength
    # Used to join nested namespaces and registered keys in FileRegistry. With namespace 'ns' and registered
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    #   key 'foo': 'ns\__foo'. With parent namespace 'ns', child namespace 'child', and registered key 'foo':
    # rubocop:enable Layout/LineLength
    #   'ns\__child\__foo'
    setting :registry_namespace_separator, default: "__", reader: true

    # @!method source
    # rubocop:todo Layout/LineLength
    # Default source class for jobs. Must meet implementation criteria in [Kiba wiki](https://github.com/thbar/kiba/wiki/Implementing-ETL-sources)
    # rubocop:enable Layout/LineLength
    setting :source, constructor: proc {
                                    Kiba::Extend::Sources::CSV
                                  }, reader: true

    # @!method destination
    # rubocop:todo Layout/LineLength
    # Default destination class for jobs. Must meet implementation criteria in [Kiba wiki](https://github.com/thbar/kiba/wiki/Implementing-ETL-destinations)
    # rubocop:enable Layout/LineLength
    setting :destination, constructor: proc {
                                         Kiba::Extend::Destinations::CSV
                                       }, reader: true

    # @return [String] prefix for warnings from the ETL
    setting :warning_label, default: "KIBA WARNING", reader: true

    # @return [Kiba::Extend::Registry::FileRegistry] A customized
    # rubocop:todo Layout/LineLength
    #   [dry-container](https://dry-rb.org/gems/dry-container/main/) for registering and resolving
    # rubocop:enable Layout/LineLength
    #   jobs
    setting :registry,
      constructor: proc { Kiba::Extend::Registry::FileRegistry.new },
      reader: true

    # rubocop:todo Layout/LineLength
    # @return [Symbol] the job definition module method expected to be present if you [define a registry
    # rubocop:enable Layout/LineLength
    #   entry hash creator as a Module](https://lyrasis.github.io/kiba-extend/file.file_registry_entry.html#module-creator-example-since-2-7-2)
    setting :default_job_method_name, default: :job, reader: true

    # ## Pre-job task settings
    #
    # rubocop:todo Layout/LineLength
    # If configured properly, the pre-job task is run when a job is run via Thor invocation. This includes
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    #   `run:job`, `run:jobs`, and `jobs:tagged -r tagvalue`. The task is run once when the Thor task is
    # rubocop:enable Layout/LineLength
    #   invoked.

    # rubocop:todo Layout/LineLength
    # @return [Boolean] whether to use Kiba::Extend's pre-job task functionality. The default is `false`
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    #   for backward compatibility, as existing projects may not have the required settings configured.
    # rubocop:enable Layout/LineLength
    setting :pre_job_task_run, default: false, reader: true

    # rubocop:todo Layout/LineLength
    # @return [String] full path to directory to which files will be moved if `pre_job_task_action ==
    # rubocop:enable Layout/LineLength
    #   :backup`. The directory will be created if it does not exist.
    setting :pre_job_task_backup_dir, default: nil, reader: true

    # rubocop:todo Layout/LineLength
    # @return [Array<String>] full paths to directories that will be affected by the specified pre-task action
    # rubocop:enable Layout/LineLength
    setting :pre_job_task_directories, default: [], reader: true

    # @return [:backup, :nuke] Controls what happens when pre-job task is run
    #
    # rubocop:todo Layout/LineLength
    #  - :backup - Moves all existing files in specified directories to backup directory created in your `:datadir`
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    #  - :nuke - Deletes all existing files in specified directories when a job is run. **Make sure you only
    # rubocop:enable Layout/LineLength
    #    specify directories that contain derived/generated files!**
    setting :pre_job_task_action, default: :backup, reader: true

    # @return [:job, nil, anyValue]
    #
    # Controls whether pre-job task is run
    #
    # rubocop:todo Layout/LineLength
    # - :job - runs pre-job task specified above whenever you invoke `thor run:job ...`. All dependency jobs
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    #   required for the invoked job will be run. This mode is recommended during development when you want
    # rubocop:enable Layout/LineLength
    #   any change in the dependency chain to get picked up.
    # rubocop:todo Layout/LineLength
    # - any other value - only regenerates missing dependency files. Useful when your data is really big
    # rubocop:enable Layout/LineLength
    #   and/or your jobs are more stable
    setting :pre_job_task_mode, default: :job, reader: true

    # @return [Boolean] whether to output results to STDOUT for debugging
    setting :job_show_me, default: false, reader: true

    # rubocop:todo Layout/LineLength
    # @return [Boolean] whether to have computer audibly say something when job is complete
    # rubocop:enable Layout/LineLength
    setting :job_tell_me, default: false, reader: true

    # rubocop:todo Layout/LineLength
    # @return [:debug, :normal, :minimal] how much output about jobs to output to STDOUT
    # rubocop:enable Layout/LineLength
    #
    # rubocop:todo Layout/LineLength
    # - :debug - tells you A LOT - helpful when developing pipelines and debugging
    # rubocop:enable Layout/LineLength
    # - :normal - reports what is running, from where, and the results
    # - :minimal - bare minimum
    setting :job_verbosity, default: :normal, reader: true

    # The section below is for backward comapatibility only

    # @since 3.2.1
    # rubocop:todo Layout/LineLength
    # Warns that nested job config settings will be deprecated and gives new setting to use
    # rubocop:enable Layout/LineLength
    def warn_unnested(name, value)
      rep_by = "job_#{name}"
      # rubocop:todo Layout/LineLength
      msg = "Kiba::Extend.config.job.#{name} setting has been replaced by Kiba::Extend.config.#{rep_by}"
      # rubocop:enable Layout/LineLength
      warn("#{Kiba::Extend.warning_label}: #{msg}")
      value
    end

    setting :job, reader: true do
      setting :show_me, default: Kiba::Extend.job_show_me, reader: true,
        constructor: proc { |name, value|
                       Kiba::Extend.warn_unnested(name, value)
                     }
      setting :tell_me, default: Kiba::Extend.job_tell_me, reader: true,
        constructor: proc { |name, value|
                       Kiba::Extend.warn_unnested(name, value)
                     }
      setting :verbosity, default: Kiba::Extend.job_verbosity, reader: true,
        constructor: proc { |name, value|
                       Kiba::Extend.warn_unnested(name, value)
                     }
    end

    # strips, collapses multiple spaces, removes terminal commas, strips again
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

    # strips, collapses multiple spaces, removes terminal commas, strips again
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
