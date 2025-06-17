# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module CombineValues
        # Combine values from given fields into the target field.
        #
        # This is like the CONCATENATE function in many spreadsheets. The given
        #   `delim` value is used as a separator between the combined values.
        #
        # **Note:** Used with defaults, this has the same function as
        #   {FullRecord}, but deletes the source fields. {FullRecord} retains
        #   source fields by default.
        #
        # If target field has the same name as one of the source fields, and
        #   `delete_sources` = true, no values are lost. The target field
        #   is not deleted.
        #
        # Blank/nil values are dropped. If `prepend_source_field_name = true`,
        #   names of blank/nil fields are omitted
        #
        # @example With defaults
        #   # Used in pipeline as:
        #   # transform CombineValues::FromFieldsWithDelimiter
        #   xform = CombineValues::FromFieldsWithDelimiter.new
        #   input = [
        #     {name: "Weddy", sex: "m", source: "adopted"},
        #     {source: "hatched", sex: "f", name: "Niblet"},
        #     {source: "", sex: "m", name: "Tiresias"},
        #     {name: "Keet", sex: nil, source: "hatched"},
        #     {name: "", sex: nil, source: nil}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {index: "Weddy m adopted"},
        #     {index: "Niblet f hatched"},
        #     {index: "Tiresias m"},
        #     {index: "Keet hatched"},
        #     {index: nil}
        #   ]
        #   expect(result).to eq(expected)
        # @example Prepending field names
        #   # Used in pipeline as:
        #   # transform CombineValues::FromFieldsWithDelimiter,
        #   #   prepend_source_field_name: true
        #   xform = CombineValues::FromFieldsWithDelimiter.new(
        #     prepend_source_field_name: true
        #   )
        #   input = [
        #     {name: "Weddy", sex: "m", source: "adopted"},
        #     {source: "hatched", sex: "f", name: "Niblet"},
        #     {source: "", sex: "m", name: "Tiresias"},
        #     {name: "Keet", sex: nil, source: "hatched"},
        #     {name: "", sex: nil, source: nil}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {index: "name: Weddy sex: m source: adopted"},
        #     {index: "name: Niblet sex: f source: hatched"},
        #     {index: "name: Tiresias sex: m"},
        #     {index: "name: Keet source: hatched"},
        #     {index: nil}
        #   ]
        #   expect(result).to eq(expected)
        # @example With custom sources, a source as target, and delim
        #   # Used in pipeline as:
        #   # transform CombineValues::FromFieldsWithDelimiter,
        #   #  sources: %i[name sex],
        #   #  target: :name,
        #   #  delim: ", "
        #   xform = CombineValues::FromFieldsWithDelimiter.new(
        #     sources: %i[name sex],
        #     target: :name,
        #     delim: ", "
        #   )
        #   input = [
        #     {name: "Weddy", sex: "m", source: "adopted"},
        #     {source: "hatched", sex: "f", name: "Niblet"},
        #     {source: "", sex: "m", name: "Tiresias"},
        #     {name: "Keet", sex: nil, source: "hatched"},
        #     {name: "", sex: nil, source: "na"}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {name: "Weddy, m", source: "adopted"},
        #     {name: "Niblet, f", source: "hatched"},
        #     {name: "Tiresias, m", source: ""},
        #     {name: "Keet", source: "hatched"},
        #     {name: nil, source: "na"}
        #   ]
        #   expect(result).to eq(expected)
        # @example Deduplicating combined values
        #   # Used in pipeline as:
        #   # transform CombineValues::FromFieldsWithDelimiter,
        #   #  sources: %i[p1 p2 p3 p4],
        #   #  target: :p,
        #   #  delim: "|",
        #   #  deduplicate: true,
        #   #  dedupe_delim: ";"
        #   xform = CombineValues::FromFieldsWithDelimiter.new(
        #     sources: %i[p1 p2 p3 p4],
        #     target: :p,
        #     delim: "|",
        #     deduplicate: true,
        #     dedupe_delim: ";"
        #   )
        #   input = [
        #     {p1: "a", p2: "b", p3: "b", p4: "a"},
        #     {p1: "a;b", p2: "b|b", p3: "b;b", p4: "a|a"}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {p: "a|b"},
        #     {p: "a|b"}
        #   ]
        #   expect(result).to eq(expected)
        # @example Deduplicate without separate dedupe_delim
        #   # Used in pipeline as:
        #   # transform CombineValues::FromFieldsWithDelimiter,
        #   #  sources: %i[p1 p2 p3 p4],
        #   #  target: :p,
        #   #  delim: "|",
        #   #  deduplicate: true
        #   xform = CombineValues::FromFieldsWithDelimiter.new(
        #     sources: %i[p1 p2 p3 p4],
        #     target: :p,
        #     delim: "|",
        #     deduplicate: true
        #   )
        #   input = [
        #     {p1: "a", p2: "b", p3: "b", p4: "a"},
        #     {p1: "a;b", p2: "b|b", p3: "b|b;b", p4: "a|a"}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {p: "a|b"},
        #     {p: "a;b|b|b;b|a"}
        #   ]
        #   expect(result).to eq(expected)
        # @note Do not use with both prepend_source_field_name and
        #   deduplicate set to true. There is no way to safely
        #   interpret the desired behavior with this combination
        #   of options.
        # @example ERROR when prepending and deduplicating
        #   # Used in pipeline as:
        #   # transform CombineValues::FromFieldsWithDelimiter,
        #   #  sources: %i[p1 p2 p3 p4],
        #   #  target: :p,
        #   #  delim: "|"
        #   #  deduplicate: true,
        #   #  prepend_source_field_name: true
        #   xform = CombineValues::FromFieldsWithDelimiter
        #   params = {
        #       sources: %i[p1 p2 p3 p4],
        #       target: :p,
        #       delim: "|",
        #       deduplicate: true,
        #       prepend_source_field_name: true
        #     }
        #   expect{ xform.new(**params) }.to raise_error(
        #     Kiba::Extend::UnsafeParameterComboError
        #   )
        class FromFieldsWithDelimiter
          include Allable # since 4.0.0

          # @param sources [Array<Symbol>, :all] Fields whose values are to be
          #   combined
          # @param target [Symbol] Field into which the combined value will be
          #   written. May be one of the source fields
          # @param delim [String] Value used to separate individual field values
          #   in combined target field
          # @param prepend_source_field_name [Boolean] Whether to insert the
          #   source field name before its value in the combined value. Field
          #   names are NOT prepended to nil or blank values. Since 4.0.0
          # @param delete_sources [Boolean] Whether to delete the source fields
          #   after combining their values into the target field. If target
          #   field name is the same as one of the source fields, the target
          #   field is not deleted. Since 4.0.0
          # @param deduplicate [Boolean] Whether to
          #   deduplicate field values that will be combined before combining
          #   them.
          # @param dedupe_delim [String] on which to split individual field
          #   values for deduplication. Can be omitted if this is the same as
          #   `delim` value, as that will also be applied AFTER this value by
          #   default.
          def initialize(sources: :all, target: :index, delim: " ",
            prepend_source_field_name: false, delete_sources: true,
            deduplicate: false, dedupe_delim: nil)
            @fields = [sources].flatten
            @target = target
            @delim = delim
            @del = delete_sources
            @prepend = prepend_source_field_name
            @deduplicate = deduplicate
            @dedupe_delim = dedupe_delim

            if prepend && deduplicate
              raise Kiba::Extend::UnsafeParameterComboError,
                "Do not run #{self.class.name} with both deduplicate and "\
                "prepend_source_field_name set to true"
            end
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            finalize_fields(row) unless fields_set

            fieldvals = fields.map { |field| field_and_value(row, field) }
              .compact
              .to_h
            fields.each { |src| row.delete(src) } if del
            row[target] = combined_value(fieldvals)

            # if prepend
            #   pvals = []
            #   vals.each_with_index do |val, i|
            #     val = "#{fields[i]}: #{val}" unless val.nil?
            #     pvals << val
            #   end
            #   vals = pvals
            # end
            # val = vals.compact.join(delim)
            # row[target] = val.empty? ? nil : val

            row
          end

          private

          attr_reader :fields, :target, :delim, :del, :prepend, :deduplicate,
            :dedupe_delim

          def field_and_value(row, field)
            val = row[field]
            return if val.blank?

            [field, val]
          end

          def combined_value(fieldvals)
            return if fieldvals.empty?
            return prepended(fieldvals) if prepend
            return deduplicated(fieldvals) if deduplicate

            fieldvals.values.join(delim)
          end

          def prepended(fieldvals)
            fieldvals.map { |fld, val| "#{fld}: #{val}" }
              .join(delim)
          end

          def deduplicated(fieldvals)
            init_split = if dedupe_delim
              fieldvals.values
                .map { |val| val.split(dedupe_delim) }
                .flatten
            else
              fieldvals.values
            end
            init_split.map { |val| val.split(delim) }
              .flatten
              .uniq
              .join(delim)
          end
        end
      end
    end
  end
end
