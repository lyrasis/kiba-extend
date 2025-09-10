# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Explode
        # This one is hard to succintly describe! Use it if you have
        #   specific fields grouped together in a row, and you want to
        #   abstract them so the fields are broader, and you reduce
        #   the number of fields.
        #
        # In the example, 3 fields in each row represent fruit names
        #   and 2 fields in each row represent colors. We want more
        #   rows, but each row should have only one fruit column and
        #   color column.
        #
        # Things to notice in example:
        #
        # * The fact that some field values are multivalued is completely
        #   ignored
        # * If all the values for a given remap group are blank, no row is added
        # * Values in fields not included in `remap_groups` are copied to every
        #   row created
        #
        # @example With defaults
        #   # Used in pipeline as:
        #   # transform Explode::ColumnsRemappedInNewRows,
        #   #   remap_groups: [
        #   #     [:f1, :c1],
        #   #     [:f2, :c2],
        #   #     [:f3]
        #   #   ],
        #   #   map_to: [:fruit, :color]
        #   xform = Explode::ColumnsRemappedInNewRows.new(
        #     remap_groups: [
        #       [:f1, :c1],
        #       [:f2, :c2],
        #       [:f3]
        #     ],
        #     map_to: [:fruit, :color]
        #   )
        #   input = [
        #     {f1: "strawberry", c1: "red", f2: "blueberry", c2: "blue",
        #       season: "spring", f3: "cherry"},
        #     {f1: "fig;honeydew", c1: "brown;green", f2: "watermelon",
        #       c2: "green", season: "summer", f3: nil},
        #     {f1: nil, c2: nil, f2: nil, c2: nil, season: "winter",
        #       f3: "grapefruit"},
        #     {f1: nil, c2: nil, f2: nil, c2: nil, season: "autumn",
        #       f3: nil}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {fruit: "strawberry", color: "red", season: "spring"},
        #     {fruit: "blueberry", color: "blue", season: "spring"},
        #     {fruit: "cherry", color: nil, season: "spring"},
        #     {fruit: "fig;honeydew", color: "brown;green", season: "summer"},
        #     {fruit: "watermelon", color: "green", season: "summer"},
        #     {fruit: "grapefruit", color: nil, season: "winter"},
        #     {fruit: nil, color: nil, season: "autumn"}
        #   ]
        #   expect(result).to eq(expected)
        class ColumnsRemappedInNewRows
          # @param remap_groups [Array(Array(Symbol))] The existing field groups that should be
          def initialize(remap_groups:, map_to:)
            @groups = remap_groups
            @map = map_to
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            to_new_rows = new_row_groups(row)
            if to_new_rows.empty?
              newrow = @map.map do |field|
                [field, nil]
              end.to_h.merge(other_fields(row))
              yield(newrow)
            else
              to_new_rows.each do |grp_data|
                newrow = @map.zip(grp_data).to_h.merge(other_fields(row))
                yield(newrow)
              end
            end
            nil
          end

          private

          def new_row_groups(row)
            @groups.map { |group| group_vals(row, group) }.reject(&:empty?)
          end

          def group_vals(row, group)
            group.map { |field| row.fetch(field, nil) }.reject(&:blank?)
          end

          def other_fields(row)
            @other_field_names ||= row.keys - @groups.flatten

            vals = @other_field_names.map { |field| row.fetch(field, nil) }
            @other_field_names.zip(vals).to_h
          end
        end
      end
    end
  end
end
