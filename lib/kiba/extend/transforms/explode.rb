# frozen_string_literal: true

# rubocop:todo Layout/LineLength

module Kiba
  module Extend
    module Transforms
      # Transformations that reshape the data, creating new rows.
      #
      # See {Reshape} for transformations that reshape without adding rows.
      module Explode
        ::Explode = Kiba::Extend::Transforms::Explode

        # This one is hard to succintly describe! Use it if you have specific fields grouped together in a row, and you want to abstract them so the fields are broader, and you reduce the number of fields.
        #
        # In the example, 3 fields in each row represent fruit names and 2 fields in each row represent colors. We want more rows, but each row should have only one fruit column and color column.
        #
        # # Example
        #
        # Input table:
        #
        # ~~~
        # | f1           | c1          | f2         | c2    | season | f3          |
        # |--------------+-------------+------------+-------+--------+-------------|
        # | strawberry   | red         | blueberry  | blue  | spring | cherry      |
        # | fig;honeydew | brown;green | watermelon | green | summer | nil         |
        # | nil          | nil         | nil        | nil   | winter | grapefruit  |
        # | nil          | nil         | nil        | nil   | autumn | nil         |
        # ~~~
        #
        # Used in pipeline as:
        #
        # ~~~
        # transform Explode::ColumnsRemappedInNewRows,
        #   remap_groups: [
        #     [:f1, :c1],
        #     [:f2, :c2],
        #     [:f3]
        #   ],
        #  map_to: [:fruit, :color]
        # ~~~
        #
        # Results in:
        #
        # ~~~
        # | fruit        | color       | season |
        # |--------------+-------------+--------|
        # | strawberry   | red         | spring |
        # | blueberry    | blue        | spring |
        # | cherry       | nil         | spring |
        # | fig;honeydew | brown;green | summer |
        # | watermelon   | green       | summer |
        # | grapefruit   | nil         | winter |
        # | nil          | nil         | autumn |
        # ~~~
        #
        # ## Things to notice
        #
        # * The fact that some field values are multivalued is completely ignored
        # * If all the values for a given remap group are blank, no row is added
        # * Values in fields not included in `remap_groups` are copied to every row created
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

        class FieldValuesToNewRows
          def initialize(target:, fields: [], multival: false, sep: " ",
            keep_nil: false, keep_empty: false)
            @fields = [fields].flatten
            @target = target
            @multival = multival
            @sep = sep
            @keep_nil = keep_nil
            @keep_empty = keep_empty
          end

          def process(row, &)
            rows = []
            other_fields = row.keys - @fields
            other_data = {}
            other_fields.each { |f| other_data[f] = row.fetch(f, nil) }

            @fields.each do |field|
              val = row.fetch(field, nil)
              vals = if val.nil?
                [nil]
              elsif val.empty?
                [""]
              elsif @multival
                val.split(@sep, -1)
              else
                [val]
              end

              vals.each do |val|
                next if !@keep_nil && val.nil?
                next if !(val.nil? || @keep_empty) && val.empty?

                new_row = other_data.clone
                new_row[@target] = val
                rows << new_row
              end
            end
            rows.each(&)
            nil
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
