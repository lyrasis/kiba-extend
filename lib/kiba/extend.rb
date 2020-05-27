require 'kiba'
require 'kiba-common/sources/csv'
require 'kiba-common/destinations/csv'

CSVOPT = {headers: true, header_converters: :symbol}
DELIM = ';'

module Kiba
  module Extend
    autoload :VERSION, 'extend/version'
    
    puts "kiba-extend version: #{Kiba::Extend::VERSION}"
      require 'kiba/extend/destinations/csv'
      require 'kiba/extend/transforms/clean'
      require 'kiba/extend/transforms/combine_values'
      require 'kiba/extend/transforms/copy'
      require 'kiba/extend/transforms/deduplicate'
      require 'kiba/extend/transforms/delete'
      require 'kiba/extend/transforms/filter_rows'
      require 'kiba/extend/transforms/merge'
      require 'kiba/extend/transforms/rename'
      require 'kiba/extend/transforms/replace'
      require 'kiba/extend/transforms/reshape'
      require 'kiba/extend/utils/lookup'

    # strips, collapses multiple spaces, removes terminal commas, strips again
    CSV::Converters[:stripplus] = lambda{ |s|
      begin
        if s.nil?
          nil
        else
          s.strip
            .gsub(/  +/, ' ')
            .sub(/,$/, '')
            .strip
        end
      rescue ArgumentError
        s
      end
    }

  end
end
