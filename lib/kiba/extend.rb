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

require 'kiba/extend/error'
require 'kiba/extend/registry/file_registry'
require 'kiba/extend/jobs'
require 'kiba/extend/jobs/job_segmenter'
require 'kiba/extend/destinations'
require 'kiba/extend/destinations/csv'

# The Kiba ETL framework for Ruby.
# `kiba-extend` extends only Kiba OSS. Kiba Pro features are not used.
#
# * [Main website](https://www.kiba-etl.org/)
# * [Github repo](https://github.com/thbar/kiba)
module Kiba
  # Provides a suite of abstract, reusable, well-tested data transformations for use in Kiba ETL pipelines
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

    # So we can call Kiba.job_segment
    Kiba.extend(Kiba::Extend::Jobs::JobSegmenter)

    # Default options used for CSV sources/destinations
    setting :csvopts, default: { headers: true, header_converters: %i[symbol downcase] }, reader: true

    # Default settings for Lambda destination
    setting :lambdaopts, default: { on_write: ->(r) { accumulator << r } }, reader: true

    # Default delimiter for splitting/joining values in multi-valued fields
    #   Example: 'a;b' -> ['a', 'b']
    setting :delim, default: '|', reader: true

    # Default subgrouping delimiter for splitting/joining values in multi-valued fields
    #   Example: 'a^^y;b^^z' -> [['a', 'y'], ['b', 'z']]
    setting :sgdelim, default: '^^', reader: true

    # Default string to be treated as though it were a null/empty value.
    setting :nullvalue, default: '%NULLVALUE%', reader: true
    
    # Default source class for jobs
    setting :source, default: Kiba::Common::Sources::CSV, reader: true

    # Default destination class for jobs
    setting :destination, default: Kiba::Extend::Destinations::CSV, reader: true

    # Prefix for warnings from the ETL
    setting :warning_label, default: 'KIBA WARNING', reader: true

    setting :registry, default: Kiba::Extend::Registry::FileRegistry, constructor: proc { |value| value.new }, reader: true
    setting :default_job_method_name, default: :job, reader: true

    # ## Pre-job task settings
    #
    # If configured properly, the pre-job task is run when a job is run via Thor invocation. This includes
    #   `run:job`, `run:jobs`, and `jobs:tagged -r tagvalue`. The task is run once when the Thor task is
    #   invoked. 
    #
    # Whether to use Kiba::Extend's pre-job task functionality. The default is `false` for backward
    #   compatibility, as existing projects may not have the required settings configured.
    setting :pre_job_task_run, default: false, reader: true
    
    # If pre_job_task_action == :backup, set the backup directory here. It will be created if it does not exist.
    setting :pre_job_task_backup_dir, default: nil, reader: true
    
    # List paths to directories that will be affected by pre-task action
    setting :pre_job_task_directories, default: [], reader: true
    
    # Controls what happens when pre-task is run
    # Options: :backup or :nuke
    #
    #  - :backup - Moves all existing files in specified directories to backup directory created in your `:datadir`
    #  - :nuke - Deletes all existing files in specified directories when a job is run. **Make sure you only specify
    #    directories that contain derived/generated files!**
    setting :pre_job_task_action, default: :backup, reader: true
    
    # Controls whether pre-job task is run
    # Options: :job (will run) or any other value
    #   :job - runs pre-job task specified above whenever you invoke `thor run:job ...`. All dependency jobs
    #   required for the invoked job will be run. This mode is recommended during development when you want
    #   any change in the dependency chain to get picked up.
    #   any other value - only regenerates missing dependency files. Useful when your data is really big and/or your
    #     jobs are more stable
    setting :pre_job_task_mode, default: :job, reader: true


    setting :job, reader: true do
      # Whether to output results to STDOUT for debugging
      setting :show_me, default: false, reader: true
      # Whether to have computer say something when job is complete
      setting :tell_me, default: false, reader: true
      # How much output about jobs to output to STDOUT
      # :debug - tells you A LOT - helpful when developing pipelines and debugging
      # :normal - reports what is running, from where, and the results
      # :minimal - bare minimum
      setting :verbosity, default: :normal, reader: true
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
