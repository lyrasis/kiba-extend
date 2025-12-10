# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        ::Lookup = Kiba::Extend::Utils::Lookup
        extend self

        # Creates hash with keycolumn value as key and array of
        # csv-rows-as-hashes as the value
        # @param file [String] path to CSV file
        # @param csvopt [Hash] options for reading/parsing CSV
        # @param keycolumn [Symbol] field name on which rows are grouped/looked
        #   up
        # @return [Hash]
        def csv_to_hash(file:, keycolumn:, csvopt: Kiba::Extend.csvopts)
          lookup = Kiba::Extend::Utils::LookupHash.new(keycolumn: keycolumn)
          CSV.foreach(File.expand_path(file), **csvopt) do |row|
            lookup.add_record(row.to_h)
          end
          lookup.hash
        end

        # Creates hash from a registered job key outside of the context of job
        #   files setup
        # @param jobkey [Symbol] registry entry key for job with namespace
        # @param lookup_on [nil,Symbol] field name on which rows are
        #   grouped/looked up; will use value defined for registry entry if not
        #   provided
        # @param csvopt [Hash] options for reading/parsing CSV
        # @return [Hash]
        def from_job(jobkey:, lookup_on: nil, csvopt: Kiba::Extend.csvopts)
          entry = Kiba::Extend::Registry.entry_for(jobkey)
          path = entry.path
          lkup = lookup_on || entry.lookup_on
          unless lkup
            fail Kiba::Extend::NoLookupOnError.new(jobkey, "Lookup.from_job")
          end
          return {} unless Kiba::Extend::Job.output?(jobkey)

          csv_to_hash(file: path, keycolumn: lkup, csvopt: csvopt)
        end

        # Turns any Enumerable where each item is a record/row hash
        #  into an expected lookup hash via Utils::LookupHash
        # @param enum [#each<Hash>] rows/records to turn into the lookup source
        # @param keycolumn [Symbol] field name on which rows are grouped/looked
        #   up
        # @return [Hash]
        def enum_to_hash(enum:, keycolumn:)
          lookup = Kiba::Extend::Utils::LookupHash.new(keycolumn: keycolumn)
          enum.each { |row| lookup.add_record(row.to_h) }
          lookup.hash
        end
      end
    end
  end
end
