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


require 'kiba/extend/registry/file_registry'
require 'kiba/extend/jobs'
require 'kiba/extend/jobs/job_segmenter'
require 'kiba/extend/destinations'
require 'kiba/extend/destinations/csv'

# These are still here to support legacy projects/unconverted tests.
# Do not call these constants in new code.
# Use Kiba::Extend.csvopts and Kiba::Extend.delim instead
# Default CSV options
CSVOPT = { headers: true, header_converters: :symbol }.freeze

# Default multivalue delimter for splitting and joining multiple values in a field
DELIM = ';'

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

    registry = Kiba::Extend::Registry::FileRegistry.new
    
    # So we can call Kiba.job_segment
    Kiba.extend(Kiba::Extend::Jobs::JobSegmenter)

    # Default options used for CSV sources/destinations
    setting :csvopts, default: { headers: true, header_converters: %i[symbol downcase] }, reader: true

    # Default settings for Lambda destination
    setting :lambdaopts, default: { on_write: ->(r) { accumulator << r } }, reader: true

    # Default delimiter for splitting/joining values in multi-valued fields
    #   Example: 'a;b' -> ['a', 'b']
    setting :delim, default: ';', reader: true

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

    setting :registry, default: registry, reader: true
    setting :default_job_method_name, default: :job, reader: true

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
