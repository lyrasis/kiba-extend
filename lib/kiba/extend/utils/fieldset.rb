# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      # Data structure class used in processing merge transforms
      class Fieldset
        attr_reader :hash

        def initialize(fields:, null_placeholder: nil)
          @null_placeholder = null_placeholder
          @hash = {}
          fields.each { |field| hash[field] = [] }
        end

        def add_constant_values(field, value)
          hash[field] = []
          value_ct.times { hash[field] << value }
        end

        def fields
          hash.keys
        end

        def join_values(delim)
          hash.transform_values! do |vals|
            placeholdered = if null_placeholder
              vals.map do |val|
                val.nil? ? null_placeholder : val
              end
            else
              vals
            end
            placeholdered.join(delim)
          end
        end

        def populate(rows)
          return self if rows.blank?

          rows.each { |row| get_field_values(row) }
          remove_valueless_rows
          self
        end

        def value_ct
          hash.values.first.length
        end

        private

        attr_reader :null_placeholder

        def get_field_values(row)
          fields.each do |field|
            fetched = row.fetch(field, nil)
            value = fetched.blank? ? nil : fetched
            hash[field] << value
          end
        end

        def remove_valueless_rows
          valueless_indices.each do |index|
            hash.each { |_field, values| values.delete_at(index) }
          end
        end

        def valueless_indices
          indices = []
          hash.values.first.each_with_index do |_element, i|
            indices << i if @hash.values.map { |vals| vals[i] }.compact.empty?
          end
          indices.sort.reverse
        end
      end
    end
  end
end
