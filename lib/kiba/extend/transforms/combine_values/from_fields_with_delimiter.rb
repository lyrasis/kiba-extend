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
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {index: "Weddy m adopted"},
        #     {index: "Niblet f hatched"},
        #     {index: "Tiresias m"},
        #     {index: 'Keet hatched'}
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
        class FromFieldsWithDelimiter
          include Allable # since 4.0.0
          include SepDeprecatable

          # @param sources [Array<Symbol>, :all] Fields whose values are to be
          #   combined
          # @param target [Symbol] Field into which the combined value will be
          #   written. May be one of the source fields
          # @param sep [String] Will be deprecated in a future version. Do not
          #   use.
          # @param delim [String] Value used to separate individual field values
          #   in combined target field
          # @param prepend_source_field_name [Boolean] Whether to insert the
          #   source field name before its value in the combined value. Since
          #   4.0.0
          # @param delete_sources [Boolean] Whether to delete the source fields
          #   after combining their values into the target field. If target
          #   field name is the same as one of the source fields, the target
          #   field is not deleted. Since 4.0.0
          def initialize(sources: :all, target: :index, sep: nil, delim: nil,
            prepend_source_field_name: false, delete_sources: true)
            @fields = [sources].flatten
            @target = target
            @delim = usedelim(
              sepval: sep,
              delimval: delim,
              calledby: self,
              default: " "
            )
            @del = delete_sources
            @prepend = prepend_source_field_name
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            finalize_fields(row) unless fields_set

            vals = fields.map { |src| row.fetch(src, nil) }
              .map { |v| v.blank? ? nil : v }

            if prepend
              pvals = []
              vals.each_with_index do |val, i|
                val = "#{fields[i]}: #{val}" unless val.nil?
                pvals << val
              end
              vals = pvals
            end
            val = vals.compact.join(delim)
            row[target] = val.empty? ? nil : val

            fields.each { |src| row.delete(src) unless src == target } if del
            row
          end

          private

          attr_reader :fields, :target, :delim, :del, :prepend
        end
      end
    end
  end
end
