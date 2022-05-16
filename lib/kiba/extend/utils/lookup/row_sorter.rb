# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        # Sorts an array of rows on a given field, according to the given parameters
        #
        # Currently this class can be used as an optional argument to
        #   {Kiba::Extend::Transforms::Merge::MultiRowLookup}, if you need to ensure values from
        #   multiple looked-up rows are merged in a particular order.
        #
        # @note This class is **not** a transform to sort the rows in a job. It was not designed
        #   or tested with more than a few rows in any given #call. It may be possible to
        #   leverage this to create a `Sort::Rows` transform in the future, but it would be
        #   subject to the same types of performance issues present with any of the "hold all rows
        #   in memory at the same time" transforms.
        #
        # Currently only supports sorting values as strings (the default) or as
        #   integers (passing `as: :to_i`). If you need to sort by dates, you must add
        #   a column to your lookup table that expresses the date as an integer. For
        #   simple/clean dates, something like this could work:
        #
        # ```
        # transform do |row|
        #   dateval = row[:datefield]
        #   row[:date_as_num] = Date.parse(dateval).jd
        #   row
        # end
        # ```
        #
        # ## Examples
        #
        # Rows:
        #
        # ```
        # rows = [
        #   { id: '1' },
        #   { id: '10' },
        #   { id: '11' },
        #   { id: '100'},
        #   { id: nil },
        #   { id: '' },
        #   { id: 'XR3' },
        #   { id: '25' }
        # ]
        # ```
        #
        # ### With defaults (asc, sorted as strings, blanks first)
        #
        # ```
        # sorter = Lookup::RowSorter.new(on: :id)
        # result = sorter.call(rows)
        # result.map{ |row| row[:id] } =>
        #   [nil, '', '1', '10', '100', '11', '25', 'XR3']
        # ```
        #
        # ### Asc, sorted as integers, blanks first
        #
        # ```
        # sorter = Lookup::RowSorter.new(on: :id, as: :to_i)
        # result = sorter.call(rows)
        # result.map{ |row| row[:id] } =>
        #   [nil, '', '1', '10', '11', '25', '100', 'XR3']
        # ```
        #
        # ### Asc, sorted as strings, blanks last
        #
        # ```
        # sorter = Lookup::RowSorter.new(on: :id, as: :to_i)
        # result = sorter.call(rows)
        # result.map{ |row| row[:id] } =>
        #   ['1', '10', '100', '11', '25', 'XR3', nil, '']
        # ```
        #
        # ### Desc, sorted as strings, blanks last
        #
        # ```
        # sorter = Lookup::RowSorter.new(on: :id, as: :to_i)
        # result = sorter.call(rows)
        # result.map{ |row| row[:id] } =>
        #   [nil, '', 'XR3', '25', '11', '100', '10', '1']
        # ```
        #
        # @since 2.8.0
        class RowSorter
          # @param on [Symbol] field on which to sort the rows
          # @param dir [:asc, :desc] sort direction
          # @param as [Symbol] method to call in order to convert field values for sorting
          # @param blanks [:first, :last] where to position blank values in the sorted list
          def initialize(on:, dir: :asc, as: nil, blanks: :first)
            @sortfield = on
            @sortdir = dir
            @sortas = as
            @blanks = blanks
          end

          # @param arr [Array<Hash>] array of rows to sort
          def call(arr)
            return arr unless sortfield

            blanks_sep = arr.group_by{ |row| row[sortfield].blank? }

            blank = blanks_sep[true]
            not_blank = blanks_sep[false]

            sorted = not_blank.map{ |row| { sortval: convert(row[sortfield]), row: row} }
              .group_by{ |row| row[:sortval].class }
              .map{ |klass, rows| [klass, sort(rows)] }
              .to_h
              .map{ |klass, rows| [klass, rows.map{ |row| row[:row] }] }
              .to_h

            arranged = arrange_sorted_rows(sorted)
            
            add_blanks(arranged, blank)
          end

          private

          attr_reader :sortfield, :sortdir, :sortas, :blanks

          def add_blanks(notblank, blank)
            sorted = notblank
            return [blank, notblank].compact.flatten if blanks == :first

            [notblank, blank].compact.flatten
          end

          def arrange_sorted_rows(sorted)
            asc = [sorted[Integer], sorted[String]]
            ordered = sortdir == :asc ? asc : asc.reverse
            ordered.compact.flatten
          end

          def convert(val)
            return val unless sortas
            
            case sortas
            when :to_i
              convert_to_i(val)
            else
              val.respond_to?(sortas) ? val.send(sortas) : val
            end
          end

          def convert_to_i(val)
            return val if val.downcase.match?(/[a-z]/)

            val.to_i
          end
          
          def sort(arr)
            asc = arr.sort_by{ |row| row[:sortval] }
            sortdir == :desc ? asc.reverse : asc
          end
        end
      end
    end
  end
end
