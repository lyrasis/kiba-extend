# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        ::Lookup = Kiba::Extend::Utils::Lookup
        extend self

        # @deprecated in 2.2.0. The original `csv_to_multi_hash` now has the name
        #   `csv_to_hash`. `csv_to_multi_hash` is now aliased to `csv_to_hash`. Since
        #   creating these methods, I never once needed to use the original `csv_to_hash`
        #   method. Any need for it can be met by the multi-hash implementation
        # @todo remove this entirely at some point
        def csv_to_hash_deprecated(file:, keycolumn:, csvopt: {})
          CSV.foreach(File.expand_path(file),
            csvopt).each_with_object({}) do |r, memo|
            memo[r.fetch(keycolumn, nil)] = r.to_h
          end
        end

        # Turns any Enumerable where each item is a record/row hash into an expected lookup
        #   hash via Utils::LookupHash
        # @param enum [#each<Hash>] rows/records to turn into the lookup source
        # @param keycolumn [Symbol] field name on which rows are grouped/looked up
        def enum_to_hash(enum:, keycolumn:)
          lookup = Kiba::Extend::Utils::LookupHash.new(keycolumn: keycolumn)
          enum.each { |row| lookup.add_record(row.to_h) }
          lookup.hash
        end

        # creates hash with keycolumn value as key and array of csv-rows-as-hashes as the value
        # @param file [String] path to CSV file
        # @param csvopt [Hash] options for reading/parsing CSV
        # @param keycolumn [Symbol] field name on which rows are grouped/looked up
        def csv_to_hash(file:, keycolumn:, csvopt: Kiba::Extend.csvopts)
          lookup = Kiba::Extend::Utils::LookupHash.new(keycolumn: keycolumn)
          CSV.foreach(File.expand_path(file), **csvopt) { |row|
            lookup.add_record(row.to_h)
          }
          lookup.hash
        end

        alias_method :csv_to_multi_hash, :csv_to_hash
      end
    end
  end
end
