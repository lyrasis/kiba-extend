# frozen_string_literal: true

require 'kiba/extend/transforms/helpers'

module Kiba
  module Extend
    module Transforms
      # Transformations to clean up data
      module Clean
        ::Clean = Kiba::Extend::Transforms::Clean

        # Sorts the multiple values within a field alphabetically
        #
        # @note This transformation does **NOT** sort the **ROWS** in a dataset. It sorts values within
        #   individual fields of a row
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | type                         |
        # |------------------------------|
        # | Person;unmapped;Organization |
        # | ;                            |
        # | nil                          |
        # |                              |
        # | Person;notmapped             |
        # | %NULLVALUE%;apple            |
        # | oatmeal;%NULLVALUE%          |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Clean::AlphabetizeFieldValues, fields: %i[type], delim: ';', usenull: false,
        #      direction: :asc
        # ```
        #
        # Results in:
        #
        # ```
        # | type                         |
        # |------------------------------|
        # | Organization;Person;unmapped |
        # | ;                            |
        # | nil                          |
        # |                              |
        # | notmapped;Person             |
        # | apple;%NULLVALUE%            |
        # | %NULLVALUE%;oatmeal          |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Clean::AlphabetizeFieldValues, fields: %i[type], delim: ';', usenull: false,
        #      direction: :desc
        # ```
        #
        # Results in:
        #
        # ```
        # | type                         |
        # |------------------------------|
        # | unmapped;Person;Organization |
        # | ;                            |
        # | nil                          |
        # |                              |
        # | Person;notmapped             |
        # | %NULLVALUE%;apple            |
        # | oatmeal;%NULLVALUE%          |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Clean::AlphabetizeFieldValues, fields: %i[type], delim: ';', usenull: true,
        #      direction: :asc
        # ```
        #
        # Results in:
        #
        # ```
        # | type                         |
        # |------------------------------|
        # | Organization;Person;unmapped |
        # | ;                            |
        # | nil                          |
        # |                              |
        # | notmapped;Person             |
        # | apple;%NULLVALUE%            |
        # | oatmeal;%NULLVALUE%          |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Clean::AlphabetizeFieldValues, fields: %i[type], delim: ';', usenull: true,
        #      direction: :desc
        # ```
        #
        # Results in:
        #
        # ```
        # | type                         |
        # |------------------------------|
        # | unmapped;Person;Organization |
        # | ;                            |
        # | nil                          |
        # |                              |
        # | Person;notmapped             |
        # | %NULLVALUE%;apple            |
        # | %NULLVALUE%;oatmeal          |
        # ```
        class AlphabetizeFieldValues
          include Kiba::Extend::Transforms::Helpers
          
          # @param fields [Array(Symbol)] names of fields to sort
          # @param delim [String] Character(s) on which to split field values
          # @param usenull [Boolean] Whether to treat `Kiba::Extend.nullvalue` as a blank in processing
          # @param direction [:asc, :desc] Direction in which to sort field values
          def initialize(fields:, delim:, usenull: false, direction: :asc)
            @fields = [fields].flatten
            @delim = delim
            @usenull = usenull
            @direction = direction
            nv = usenull ? Kiba::Extend.nullvalue : nil
            @value_getter = Helpers::FieldValueGetter.new(fields: fields, delim: delim, treat_as_null: nv)
          end

          # @param row [Hash{ Symbol => String }]
          def process(row)
            value_getter.call(row).each do |field, val|
              next unless val[delim]

              row[field] = sort_values(val.split(delim)).join(delim)
            end
            row
          end

          private

          attr_reader :fields, :delim, :usenull, :direction, :value_getter

          def process_for_sort(val)
            if usenull
              val.gsub(Kiba::Extend.nullvalue, 'zzzzzzzzzzzzzz').downcase.gsub(/[^[:alnum:][:space:]]/, '')
            else
              val.downcase.gsub(/[^[:alnum:][:space:]]/, '')
            end
          end

          def sort_values(vals)
            if direction == :asc
              vals.sort_by { |v| process_for_sort(v) } 
            else
              vals.sort_by { |v| process_for_sort(v) }.reverse
            end
          end
        end

        class ClearFields
          def initialize(fields:, if_equals: nil)
            @fields = [fields].flatten
            @if_equals = if_equals
          end

          # @param row [Hash{ Symbol => String }]
          def process(row)
            @fields.each do |field|
              if @if_equals.nil?
                row[field] = nil
              elsif row[field] == @if_equals
                row[field] = nil
              end
            end
            row
          end
        end

        class DowncaseFieldValues
          def initialize(fields:)
            @fields = [fields].flatten
          end

          # @param row [Hash{ Symbol => String }]
          def process(row)
            @fields.each do |field|
              val = row.fetch(field)
              row[field] = val.is_a?(String) ? val.downcase : val
            end
            row
          end
        end

        class EmptyFieldGroups
          # @param groups [Array(Array(Symbol))] Each of the arrays inside groups should list all fields that are
          #   part of a repeating field group or field subgroup
          # @param sep [String] delimiter used to split/join field values
          # @param use_nullvalue [String, false] if a string, will insert that string before any sep at beginning
          #   of string, after any sep end of string, and between any two sep with nothing in between. It considers
          #   thias a blank
          #   value, so if all values in a field are %NULLVALUE%, the field will be nil-ed out.
          def initialize(groups:, sep:, use_nullvalue: false)
            @groups = groups
            @sep = sep
            @use_nullvalue = use_nullvalue
          end

          # @param row [Hash{ Symbol => String }]
          def process(row)
            @groups.each { |group| process_group(row, group) }
            row
          end

          private

          def process_group(row, group)
            thisgroup = group.map { |field| row.fetch(field, '') }
              .map{ |val| @use_nullvalue ? add_null_values(val) : val  }
              .map{ |val| val.nil? ? [] : " #{val} ".split(@sep) }
              .map{ |arr| arr.map(&:strip) }

            cts = thisgroup.map(&:size).uniq.reject(&:zero?)

            to_delete = []

            if cts.size > 1
              # do nothing - different numbers of elements, not safe to edit
            elsif cts.size.zero?
              # do nothing - all fields already blank
            else
              thisgroup.first.each_with_index { |_element, i| to_delete << i if all_empty?(thisgroup, i) }
              to_delete.sort.reverse.each do |i|
                thisgroup.each { |arr| arr.delete_at(i) }
              end
              thisgroup.each_with_index { |arr, i| row[group[i]] = arr.empty? ? nil : arr.join(@sep) }
            end
          end

          def empty_val(str)
            return true if str.blank?
            return true if str == '%NULLVALUE%' && @use_nullvalue

            false
          end

          def add_null_values(str)
            return str if str.nil?

            padfront = str.start_with?(@sep) ? "%NULLVALUE%#{str}" : str
            padend = padfront.end_with?(@sep) ? "#{padfront}%NULLVALUE%" : padfront
            padded = padend.gsub("#{@sep}#{@sep}", "#{@sep}%NULLVALUE%#{@sep}")
            padded
          end

          def all_empty?(group, index)
            thesevals = group.map { |arr| arr[index] }
              .map { |val| empty_val(val) ? nil : val }
              .uniq
              .compact
            thesevals.empty? ? true : false
          end
        end

        class RegexpFindReplaceFieldVals
          include Allable
          
          def initialize(fields:, find:, replace:, casesensitive: true, multival: false, sep: nil, debug: false)
            @fields = [fields].flatten
            @find = Regexp.new(find) if casesensitive == true
            @find = Regexp.new(find, Regexp::IGNORECASE) if casesensitive == false
            @replace = replace
            @debug = debug
            @mv = multival
            @sep = sep
          end

          # @param row [Hash{ Symbol => String }]
          def process(row)
            finalize_fields(row)
            
            fields.each do |field|
              oldval = row.fetch(field, nil)
              next if oldval.nil?
              next unless oldval.is_a?(String)

              newval = mv ? mv_find_replace(oldval) : sv_find_replace(oldval)
              target = debug ? "#{field}_repl".to_sym : field
              row[target] = if newval.nil?
                              nil
                            else
                              newval.empty? ? nil : newval
                            end
            end
            row
          end

          private

          attr_reader :fields, :find, :replace, :debug, :mv, :sep

          def mv_find_replace(val)
            val.split(sep).map { |v| v.gsub(find, replace) }.join(sep)
          end

          def sv_find_replace(val)
            val.gsub(find, replace)
          end
        end

        class StripFields
          def initialize(fields:)
            @fields = [fields].flatten
          end

          # @param row [Hash{ Symbol => String }]
          def process(row)
            @fields.each do |field|
              val = row.fetch(field, nil)
              row[field] = if val.nil? || val.empty?
                             nil
                           else
                             val.strip
                           end
            end
            row
          end
        end
      end
    end
  end
end
