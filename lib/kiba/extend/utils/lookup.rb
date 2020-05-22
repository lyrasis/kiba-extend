module Kiba
  module Extend
    module Utils
      module Lookup
        ::Lookup = Kiba::Extend::Utils::Lookup
        # use when keycolumn values are unique
        # creates hash with keycolumn value as key and csv-row-as-hash as the value
        def self.csv_to_hash(file:, csvopt: {}, keycolumn:)
          CSV.foreach(File.expand_path(file), csvopt).each_with_object({}) do |r, memo|
            memo[r.fetch(keycolumn)] = r.to_h
          end
        end

        # use when keycolumn values are not unique
        # creates hash with keycolumn value as key and array of csv-rows-as-hashes as the value
        def self.csv_to_multi_hash(file:, csvopt: {}, keycolumn:)
          CSV.foreach(File.expand_path(file), csvopt).each_with_object({}) do |r, memo|
            k = r.fetch(keycolumn)
            if memo.has_key?(k)
              memo[k] << r.to_h
            else
              memo[k] = [r.to_h]
            end
          end
        end
      end
    end
  end
end
