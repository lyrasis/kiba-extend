# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/object"
require 'kiba'
require 'kiba-common/sources/csv'
require 'kiba-common/destinations/csv'
require 'pry'
require 'xxhash'

require 'kiba/extend/version'


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
    puts "kiba-extend version: #{Kiba::Extend::VERSION}"

    # Require application files
    Dir.glob("#{__dir__}/**/*").sort.select{ |path| path.match?(/\.rb$/) }.each do |rbfile|
      require rbfile.delete_prefix("#{File.expand_path(__dir__)}/lib/")
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
