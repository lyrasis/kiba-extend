# frozen_string_literal: true

require 'amazing_print'
require 'active_support'
require 'active_support/core_ext/object'
require 'dry-configurable'
require 'kiba'
require 'kiba-common/sources/csv'
require 'kiba-common/sources/enumerable'
require 'kiba-common/destinations/csv'
require 'kiba-common/destinations/lambda'
require 'pry'
require 'xxhash'
require 'zeitwerk'

# The Kiba ETL framework for Ruby.
# `kiba-extend` extends only Kiba OSS. Kiba Pro features are not used.
#
# * [Main website](https://www.kiba-etl.org/)
# * [Github repo](https://github.com/thbar/kiba)
module Kiba
  # Handles:
  #
  # - auto-loading of the code
  # - extending `Kiba` with `Kiba::Extend::Jobs::JobSegmenter` so we can call `Kiba.job_segment`
  # - defining config settings, all of which can be overridden by project applications using
  #   `kiba-extend`
  #
  # Also defines some CSV converters:
  #
  # - `:stripextra` -- strips leading/trailing spaces, collapses multiple spaces, removes terminal commas,
  #   strips again
  # - `:nulltonil` -- replaces any values that are a literal string NULL with a nil value
  # - `:stripplus` -- strips leading/trailing spaces, collapses multiple spaces, removes terminal commas,
  #   strips again, removes "NULL" (i.e. literal string "NULL" becomes a `nilValue`
  #
  # Note that `:stripplus` combines the functionality of `:stripextra` and `:nulltonil`
  module Extend
    module_function
    extend Dry::Configurable

    def loader
      @loader ||= setup_loader
    end

    private def setup_loader
              @loader = Zeitwerk::Loader.new
              ke_dir = Gem.loaded_specs['kiba-extend'].full_gem_path
              @loader.push_dir(File.join(ke_dir, 'lib', 'kiba', 'extend'), namespace: Kiba::Extend)
              @loader.inflector.inflect(
                'normalize_for_id' => 'NormalizeForID',
                'convert_to_id' => 'ConvertToID',
                'version' => 'VERSION',
                'csv' => 'CSV'
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
    setting :csvopts, default: { headers: true, header_converters: %i[symbol downcase] }, reader: true

    # @return [Hash] default settings for Lambda destination
    setting :lambdaopts, default: { on_write: ->(r) { accumulator << r } }, reader: true

    # @return [String] default delimiter for splitting/joining values in multi-valued fields
    # @example If :delim == '|'
    #   'a|b' -> ['a', 'b']
    setting :delim, default: '|', reader: true

    # @return [String] default subgrouping delimiter for splitting/joining values in multi-valued fields
    # @example If :delim == '|' and :sgdelim == '^^'
    #   'a^^y|b^^z' -> [['a', 'y'], ['b', 'z']]
    setting :sgdelim, default: '^^', reader: true

    # @return [String] default string to be treated as though it were a null/empty value.
    setting :nullvalue, default: '%NULLVALUE%', reader: true

    # @return [String] used to join nested namespaces and registered keys in FileRegistry
    # @example With namespace 'ns' and registered key 'foo'
    #   'ns__foo'
    # @example With parent namespace 'ns', child namespace 'child', and registered key 'foo'
    #   'ns__child__foo'
    setting :registry_namespace_separator, default: '__', reader: true
    
    # @!method source
    # Default source class for jobs. Must meet implementation criteria in [Kiba wiki](https://github.com/thbar/kiba/wiki/Implementing-ETL-sources)
    setting :source, default: Kiba::Common::Sources::CSV, reader: true

    # @!method destination
    # Default destination class for jobs. Must meet implementation criteria in [Kiba wiki](https://github.com/thbar/kiba/wiki/Implementing-ETL-destinations)
    setting :destination, constructor: proc{ Kiba::Extend::Destinations::CSV }, reader: true

    # @return [String] prefix for warnings from the ETL
    setting :warning_label, default: 'KIBA WARNING', reader: true

    # @return [Kiba::Extend::Registry::FileRegistry] A customized
    #   [dry-container](https://dry-rb.org/gems/dry-container/main/) for registering and resolving
    #   jobs
    setting :registry,
      constructor: proc{ Kiba::Extend::Registry::FileRegistry.new },
      reader: true

    # @return [Symbol] the job definition module method expected to be present if you [define a registry
    #   entry hash creator as a Module](https://lyrasis.github.io/kiba-extend/file.file_registry_entry.html#module-creator-example-since-2-7-2)
    setting :default_job_method_name, default: :job, reader: true

    # ## Pre-job task settings
    #
    # If configured properly, the pre-job task is run when a job is run via Thor invocation. This includes
    #   `run:job`, `run:jobs`, and `jobs:tagged -r tagvalue`. The task is run once when the Thor task is
    #   invoked. 
    
    # @return [Boolean] whether to use Kiba::Extend's pre-job task functionality. The default is `false`
    #   for backward compatibility, as existing projects may not have the required settings configured.
    setting :pre_job_task_run, default: false, reader: true
    
    # @return [String] full path to directory to which files will be moved if `pre_job_task_action ==
    #   :backup`. The directory will be created if it does not exist.
    setting :pre_job_task_backup_dir, default: nil, reader: true
    
    # @return [Array<String>] full paths to directories that will be affected by the specified pre-task action
    setting :pre_job_task_directories, default: [], reader: true
    
    # @return [:backup, :nuke] Controls what happens when pre-job task is run
    #
    #  - :backup - Moves all existing files in specified directories to backup directory created in your `:datadir`
    #  - :nuke - Deletes all existing files in specified directories when a job is run. **Make sure you only
    #    specify directories that contain derived/generated files!**
    setting :pre_job_task_action, default: :backup, reader: true
    
    # @return [:job, *] Controls whether pre-job task is run
    #
    # - :job - runs pre-job task specified above whenever you invoke `thor run:job ...`. All dependency jobs
    #   required for the invoked job will be run. This mode is recommended during development when you want
    #   any change in the dependency chain to get picked up.
    # - any other value - only regenerates missing dependency files. Useful when your data is really big
    #   and/or your jobs are more stable
    setting :pre_job_task_mode, default: :job, reader: true

    # @return [Boolean] whether to output results to STDOUT for debugging
    setting :job_show_me, default: false, reader: true

    # @return [Boolean] whether to have computer audibly say something when job is complete
    setting :job_tell_me, default: false, reader: true
    
    # @return [:debug, :normal, :minimal] how much output about jobs to output to STDOUT
    #
    # - :debug - tells you A LOT - helpful when developing pipelines and debugging
    # - :normal - reports what is running, from where, and the results
    # - :minimal - bare minimum
    setting :job_verbosity, default: :normal, reader: true

    
    # The section below is for backward comapatibility only
    def warn_unnested(name, value)
      rep_by = "job_#{name}"
      msg = "Kiba::Extend.config.job.#{name} setting has been replaced by Kiba::Extend.config.#{rep_by}"
      warn("#{Kiba::Extend.warning_label}: #{msg}")
      value
    end

    setting :job, reader: true do
      setting :show_me, default: Kiba::Extend.job_show_me, reader: true,
        constructor: proc{ |name, value| Kiba::Extend.warn_unnested(name, value) }
      setting :tell_me, default: Kiba::Extend.job_tell_me, reader: true,
        constructor: proc{ |name, value| Kiba::Extend.warn_unnested(name, value) }
      setting :verbosity, default: Kiba::Extend.job_verbosity, reader: true,
        constructor: proc{ |name, value| Kiba::Extend.warn_unnested(name, value) }
    end

    
    # strips, collapses multiple spaces, removes terminal commas, strips again
    # removes "NULL"/treats as nilValue
    CSV::Converters[:stripplus] = lambda { |s|
      begin
        if s.nil?
          nil
        elsif s == 'NULL'
          nil
        else
          s.strip
           .gsub(/  +/, ' ')
           .sub(/,$/, '')
           .sub(/^%(LINEBREAK|CRLF)%/, '')
           .sub(/%(LINEBREAK|CRLF)%$/, '')
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
            .gsub(/  +/, ' ')
            .sub(/,$/, '')
            .sub(/^%(LINEBREAK|CRLF)%/, '')
            .sub(/%(LINEBREAK|CRLF)%$/, '')
            .strip
        end
      rescue ArgumentError
        s
      end
    }

    # replaces any values that are a literal string NULL with a nil value
    CSV::Converters[:nulltonil] = lambda { |s|
      begin
        if s == 'NULL'
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
