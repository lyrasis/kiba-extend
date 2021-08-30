# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/object'
require 'dry-configurable'
require 'kiba'
require 'kiba-common/sources/csv'
require 'kiba-common/sources/enumerable'
require 'kiba-common/destinations/csv'
require 'kiba-common/destinations/lambda'
require 'pry'
require 'byebug'
require 'xxhash'

# require 'kiba/extend/version'

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
    extend self
    extend Dry::Configurable

    # Require application files
    Dir.glob("#{__dir__}/**/*").sort.select { |path| path.match?(/\.rb$/) }.each do |rbfile|
      require rbfile.delete_prefix("#{File.expand_path(__dir__)}/lib/")
    end

    # So we can call Kiba.job_segment
    Kiba.extend(Kiba::Extend::Jobs::JobSegmenter)

    # Default options for reading/writing CSVs
    setting :csvopts, { headers: true, header_converters: %i[symbol downcase] }, reader: true

    # Default settings for Lambda destination
    setting :lambdaopts, { on_write: ->(r) { accumulator << r } }, reader: true

    # Default delimiter for splitting/joining values in multi-valued fields
    setting :delim, ';', reader: true

    # Default source class for jobs
    setting :source, Kiba::Common::Sources::CSV, reader: true

    # Default destination class for jobs
    setting :destination, Kiba::Extend::Destinations::CSV, reader: true

    # Prefix for warnings from the ETL
    setting :warning_label, 'KIBA WARNING', reader: true

    setting :registry, Kiba::Extend::FileRegistry.new, reader: true

    setting :job, reader: true do
      # Whether to output results to STDOUT for debugging
      setting :show_me, false, reader: true
      # Whether to have computer say something when job is complete
      setting :tell_me, false, reader: true
      # How much output about jobs to output to STDOUT
      # :debug - tells you A LOT - helpful when developing pipelines and debugging
      # :normal - reports what is running, from where, and the results
      # :minimal - bare minimum
      setting :verbosity, :normal, reader: true
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
