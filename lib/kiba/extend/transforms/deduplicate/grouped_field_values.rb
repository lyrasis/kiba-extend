# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Deduplicate
        # Field value deduplication that is at least semi-safe for use with grouped fields that expect the same number
        #   of values for each field in the grouping
        #
        # @note Tread with caution, as this has not been used much and is not extensively tested
        # @todo Refactor this hideous mess
        #
        #
        # Input table:
        #
        # ```
        # | name                  | work                   | role                                   |
        # |-----------------------+------------------------+----------------------------------------|
        # | Fred;Freda;Fred;James | Report;Book;Paper;Book | author;photographer;editor;illustrator |
        # | ;                     | ;                      | ;                                      |
        # | Martha                | Book                   | contributor                            |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Deduplicate::GroupedFieldValues,
        #   on_field: :name,
        #   grouped_fields: %i[work role],
        #   sep: ';'
        # ```
        #
        # Results in:
        #
        # ```
        # | name             | work             | role                            |
        # |------------------+------------------+---------------------------------|
        # | Fred;Freda;James | Report;Book;Book | author;photographer;illustrator |
        # | nil              | nil              | nil                             |
        # | Martha           | Book             | contributor                     |
        # ```
        #
        class GroupedFieldValues
          # @param on_field [Symbol] the value to be deduplicated
          # @param sep [String] used to split/join multivalued field values
          # @param grouped_fields [Array<Symbol>] other fields in the same multi-field grouping as `field`
          def initialize(on_field:, sep:, grouped_fields: [])
            @field = on_field
            @other = grouped_fields
            @sep = sep
          end

          # @param row [Hash{ Symbol => String, nil }]
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
      end
    end
  end
end
