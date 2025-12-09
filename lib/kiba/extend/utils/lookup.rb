# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        ::Lookup = Kiba::Extend::Utils::Lookup
        extend self

        # Turns any Enumerable where each item is a record/row hash
        #  into an expected lookup hash via Utils::LookupHash
        # @param enum [#each<Hash>] rows/records to turn into the lookup source
        # @param keycolumn [Symbol] field name on which rows are grouped/looked
        #   up
        def enum_to_hash(enum:, keycolumn:)
          lookup = Kiba::Extend::Utils::LookupHash.new(keycolumn: keycolumn)
          enum.each { |row| lookup.add_record(row.to_h) }
          lookup.hash
        end

        # Creates hash with keycolumn value as key and array of
        # csv-rows-as-hashes as the value
        # @param file [String] path to CSV file
        # @param csvopt [Hash] options for reading/parsing CSV
        # @param keycolumn [Symbol] field name on which rows are grouped/looked
        #   up
        def csv_to_hash(file:, keycolumn:, csvopt: Kiba::Extend.csvopts)
          lookup = Kiba::Extend::Utils::LookupHash.new(keycolumn: keycolumn)
          CSV.foreach(File.expand_path(file), **csvopt) do |row|
            lookup.add_record(row.to_h)
          end
          lookup.hash
        end

        alias_method :csv_to_multi_hash, :csv_to_hash
      end
    end
  end
end
