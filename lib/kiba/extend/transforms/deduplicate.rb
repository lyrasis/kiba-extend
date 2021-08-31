# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Tranformations that do some sort of data deduplication
      module Deduplicate
        ::Deduplicate = Kiba::Extend::Transforms::Deduplicate

        # Removes the value(s) of `source` from `targets`
        #
        # Input table:
        #
        # ```
        # | x   | y   | z   |
        # |-----+-----+-----|
        # | a   | a   | b   |
        # | a   | a   | a   |
        # | a   | b;a | a;c |
        # | a;b | b;a | a;c |
        # | a   | aa  | bat |
        # | nil | a   | nil |
        # |     | ;a  | b;  |
        # | a   | nil | nil |
        # | a   | A   | a   |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Deduplicate::Fields, source: :x, targets: %i[y z], multival: true, sep: ';'
        # ```
        #
        # Results in:
        #
        # ```
        # | x   | y   | z   |
        # |-----+-----+-----|
        # | a   | nil | b   |
        # | a   | nil | nil |
        # | a   | b   | c   |
        # | a;b | nil | c   |
        # | a   | aa  | bat |
        # | nil | a   | nil |
        # |     | a   | b   |
        # | a   | nil | nil |
        # | a   | A   | nil |
        # ```
        #
        class Fields
          def initialize(source:, targets:, casesensitive: true, multival: false, sep: DELIM)
            @source = source
            @targets = targets
            @casesensitive = casesensitive
            @multival = multival
            @sep = sep
          end

          # @private
          def process(row)
            sourceval = row.fetch(@source, nil)
            return row if sourceval.nil?

            targetvals = @targets.map { |target| row.fetch(target, nil) }
            return row if targetvals.compact.empty?

            sourceval = @multival ? sourceval.split(@sep, -1).map(&:strip) : [sourceval.strip]
            targetvals = if @multival
                           targetvals.map { |val| val.split(@sep, -1).map(&:strip) }
                         else
                           targetvals.map { |val| [val.strip] }
                         end

            if sourceval.blank?
              targetvals = targetvals.map { |vals| vals.reject(&:blank?) }
            elsif @casesensitive
              targetvals = targetvals.map { |vals| vals - sourceval }
            else
              sourceval = sourceval.map(&:downcase)
              targetvals = targetvals.map { |vals| vals.reject { |val| sourceval.include?(val.downcase) } }
            end

            targetvals = if @multival
                           targetvals.map { |vals| vals&.join(@sep) }
                         else
                           targetvals.map(&:first)
                         end
            targetvals = targetvals.map { |val| val.blank? ? nil : val }

            targetvals.each_with_index { |val, i| row[@targets[i]] = val }

            row
          end
        end

        # Removes duplicate values within the given field(s)
        #
        # Processes one field at a time. Splits value on sep, and keeps only the unique values
        # @note This is NOT safe for use with groupings of fields whose multi-values are expected
        #   to be the same length
        #
        # Input table:
        #
        # ```
        # | foo         | bar       |
        # |-------------------------|
        # | 1;1;1;2;2;2 | a;A;b;b;b |
        # |             | q;r;r     |
        # | 1           | 2         |
        # | 1           | 2         |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # @deduper = {}
        # transform Deduplicate::FieldValues, fields: %i[foo bar], sep: ';'
        # ```
        #
        # Results in:
        #
        # ```
        # | foo   | bar     |
        # |-----------------|
        # | 1;2   | a;A;b   |
        # |       | q;r     |
        # | 1     | 2       |
        # | 1     | 2       |
        # ```
        #
        class FieldValues
          def initialize(fields:, sep:)
            @fields = fields
            @sep = sep
          end

          # @private
          def process(row)
            @fields.each do |field|
              val = row.fetch(field)
              row[field] = val.to_s.split(@sep).uniq.join(@sep) unless val.nil?
            end
            row
          end
        end

        # Adds a field (`in_field`) containing 'y' or 'n', indicating whether value of `on_field` is a duplicate
        #
        # The first instance of a value in `on_field` is always marked `n`. Subsequent rows containing the same
        #   value will be marked 'y'
        #
        # Use this transform if you need to retain/report on what will be treated as a duplicate. Use
        #   {FilterRows::FieldEqualTo} to extract only the duplicate rows and/or to keep only the
        #   non-duplicate rows
        #
        # To delete duplicates all in one step, use {Deduplicate::Table}
        #
        # Input table:
        #
        # ```
        # | foo | bar | combined  |
        # |-----------------------|
        # | a   | b   | a b       |
        # | c   | d   | c d       |
        # | c   | e   | c e       |
        # | c   | d   | c d       |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # @deduper = {}
        # transform Deduplicate::Flag, on_field: :combined, in_field: :duplicate, using: @deduper
        # ```
        #
        # Results in:
        #
        # ```
        # | foo | bar | combined | duplicate |
        # |----------------------------------|
        # | a   | b   | a b      | n         |
        # | c   | d   | c d      | n         |
        # | c   | e   | c e      | n         |
        # | c   | d   | c d      | y         |
        # ```
        #
        class Flag
          # @param on_field [Symbol] Field on which to deduplicate
          # @param in_field [Symbol] New field in which to add 'y' or 'n'
          # @param using [Hash] An empty Hash, set as an instance variable in your job definition before you
          #   use this transform
          def initialize(on_field:, in_field:, using:)
            @on = on_field
            @in = in_field
            @using = using
          end

          # @private
          def process(row)
            val = row.fetch(@on)
            if @using.key?(val)
              row[@in] = 'y'
            else
              @using[val] = nil
              row[@in] = 'n'
            end
            row
          end
        end

        class GroupedFieldValues
          def initialize(on_field:, sep:, grouped_fields: [])
            @field = on_field
            @other = grouped_fields
            @sep = sep
          end

          # @private
          def process(row)
            fv = row.fetch(@field)
            seen = []
            delete = []
            unless fv.nil?
              fv = fv.split(@sep)
              valfreq = get_value_frequency(fv)
              fv.each_with_index do |val, i|
                if valfreq[val] > 1
                  if seen.include?(val)
                    delete << i
                  else
                    seen << val
                  end
                end
              end
              row[@field] = fv.uniq.join(@sep)

              if delete.size.positive?
                delete = delete.sort.reverse
                h = {}
                @other.each { |of| h[of] = row.fetch(of) }
                h = h.reject { |_f, val| val.nil? }.to_h
                h.each { |f, val| h[f] = val.split(@sep) }
                h.each do |f, val|
                  delete.each { |i| val.delete_at(i) }
                  row[f] = val.size.positive? ? val.join(@sep) : nil
                end
              end
            end

            fv = row.fetch(@field, nil)
            if !fv.nil? && fv.empty?
              row[@field] = nil
              @other.each { |f| row[f] = nil }
            end

            row
          end

          private

          def get_value_frequency(fv)
            h = {}
            fv.uniq.each { |v| h[v] = 0 }
            fv.uniq { |v| h[v] += 1 }
            h
          end
        end

        # Given a field on which to deduplicate, removes duplicate rows from table
        #
        # Keeps the row with the first instance of the value in the deduplicating field
        #
        # Tip: Use {CombineValues::FromFieldsWithDelimiter} or {CombineValues::FullRecord} to create a combined
        #   field on which to deduplicate
        #
        # @note This transform runs in memory, so for very large sources, it may take a long time or fail. In this
        #   case, use a combination of {Deduplicate::Flag} and {FilterRows::FieldEqualTo}
        #
        # Input table:
        #
        # ```
        # | foo | bar | baz |  combined |
        # |-----------------------------|
        # | a   | b   | f   | a b       |
        # | c   | d   | g   | c d       |
        # | c   | e   | h   | c e       |
        # | c   | d   | i   | c d       |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Deduplicate::Table, fields: :combined, delete_field: true
        # ```
        #
        # Results in:
        #
        # ```
        # | foo | bar | baz |
        # |-----------------|
        # | a   | b   | f   |
        # | c   | d   | g   |
        # | c   | e   | h   |
        # ```
        #
        class Table
          def initialize(field:, delete_field: false)
            @field = field
            @deduper = {}
            @delete = delete_field
          end

          def process(row)
            field_val = row.fetch(@field, nil)
            return if field_val.blank?
            return if @deduper.key?(field_val)

            @deduper[field_val] = row
            nil
          end

          def close
            @deduper.values.each do |row|
              row.delete(@field) if @delete
              yield row
            end
          end
        end
      end
    end
  end
end
