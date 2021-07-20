require 'kiba'
require 'kiba-common/sources/csv'
require 'kiba-common/destinations/csv'
require 'pry'
require 'active_support/all'
require 'xxhash'
require 'facets/kernel/blank'

CSVOPT = { headers: true, header_converters: :symbol }
DELIM = ';'

# The Kiba ETL framework for Ruby.
# `kiba-extend` extends only Kiba OSS. Kiba Pro features are not used.
#
# * [Main website](https://www.kiba-etl.org/)
# * [Github repo](https://github.com/thbar/kiba)
module Kiba
  # Provides a suite of abstract, reusable, well-tested data transformations for use in Kiba ETL pipelines
  module Extend
    autoload :VERSION, 'extend/version'

    puts "kiba-extend version: #{Kiba::Extend::VERSION}"

    require 'kiba/extend/fieldset'
    require 'kiba/extend/destinations/csv'
    require 'kiba/extend/transforms/append'
    require 'kiba/extend/transforms/clean'
    require 'kiba/extend/transforms/combine_values'
    require 'kiba/extend/transforms/copy'
    require 'kiba/extend/transforms/deduplicate'
    require 'kiba/extend/transforms/cspace'
    require 'kiba/extend/transforms/delete'
    require 'kiba/extend/transforms/explode'
    require 'kiba/extend/transforms/filter_rows'
    require 'kiba/extend/transforms/merge'
    require 'kiba/extend/transforms/ms_access'
    require 'kiba/extend/transforms/prepend'
    require 'kiba/extend/transforms/rename'
    require 'kiba/extend/transforms/replace'
    require 'kiba/extend/transforms/reshape'
    require 'kiba/extend/transforms/split'
    require 'kiba/extend/utils/lookup'

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
