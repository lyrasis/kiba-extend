module Kiba
  module Extend
    class Fieldset
      def initialize(fields)
        @hash = {}
        fields.each { |field| @hash[field] = [] }
      end

      def add_constant_values(field, value)
        @hash[field] = []
        value_ct.times { @hash[field] << value }
      end

      def fields
        @hash.keys
      end

      attr_reader :hash

      def join_values(delim)
        @hash.transform_values! { |vals| vals.join(delim) }
      end

      def populate(rows)
        return if rows.empty?

        rows.each { |row| get_field_values(row) }
        remove_valueless_rows
      end

      def value_ct
        @hash.values.first.length
      end

      private

      def get_field_values(row)
        fields.each do |field|
          fetched = row.fetch(field, nil)
          value = fetched.blank? ? nil : fetched
          @hash[field] << value
        end
      end

      def remove_valueless_rows
        valueless_indices.each do |index|
          @hash.each { |_field, values| values.delete_at(index) }
        end
      end

      def valueless_indices
        indices = []
        @hash.values.first.each_with_index do |_element, i|
          indices << i if @hash.values.map { |vals| vals[i] }.compact.empty?
        end
        indices.sort.reverse
      end
    end
  end
end
