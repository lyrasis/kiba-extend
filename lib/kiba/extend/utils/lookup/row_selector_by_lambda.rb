# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        # rubocop:todo Layout/LineLength
        # Called by transforms that have a `conditions` parameter, when a Lambda is passed in as the
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   conditional logic. This is a more straightforward and flexible method of controlling which rows
        # rubocop:enable Layout/LineLength
        #   are selected/operated on than the hideous Hash conditions format.
        #
        # rubocop:todo Layout/LineLength
        # The lambda Proc passed in must be defined with two arguments. The first should be a single
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   data row, typically the source/target row for a data merge or other operation. The
        # rubocop:enable Layout/LineLength
        #   second is an array of data rows.
        #
        # rubocop:todo Layout/LineLength
        # Because of how this RowSelector is called by different transforms, both arguments need to be
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   defined, even if you aren't going to use them in the logic encapsulated in the Lambda.
        # rubocop:enable Layout/LineLength
        #
        # rubocop:todo Layout/LineLength
        # The lambda Proc must return an array of rows meeting the given criteria.
        # rubocop:enable Layout/LineLength
        #
        # ## Examples
        #
        # In your job transforms:
        #
        # ```
        # conditions = ->(origrow, mergerows) do
        #   latest = mergerows.sort_by{ |row| row[:addressid].to_i }
        #              .last
        #   [latest]
        # end
        # transform Merge::MultiRowLookup,
        #   lookup: addresses,
        #   keycolumn: :contactid,
        # rubocop:todo Layout/LineLength
        #   fieldmap: { address: :display_address, addresstype: address_category },
        # rubocop:enable Layout/LineLength
        #   conditions: conditions
        # ```
        #
        # Assuming `addressid` increments as new addresses are added, sorting
        # rubocop:todo Layout/LineLength
        #   the matching lookup rows by that field value, and taking the last (largest) value
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   should ensure we are merging in only the lastest address value per contact.
        # rubocop:enable Layout/LineLength
        #
        # In your job transforms:
        #
        # ```
        # conditions = ->(target, lkuprows) do
        #   return [] unless target[:active] == '1'
        #
        #   lkuprows.select{ |row| row[:active] == '1' }
        # end
        # transform Merge::MultiRowLookup,
        #   lookup: addresses,
        #   keycolumn: :contactid,
        # rubocop:todo Layout/LineLength
        #   fieldmap: { address: :display_address, addresstype: address_category },
        # rubocop:enable Layout/LineLength
        #   conditions: conditions
        # ```
        #
        # rubocop:todo Layout/LineLength
        # This assumes the source table (listing contacts) indicates whether a contact is active or not.
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   In addition, the addresses table indicates whether each address is active. This will cause
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   no addresses to be merged in for inactive contacts. For active contacts, only active
        # rubocop:enable Layout/LineLength
        #   addresses will be merged in.
        #
        # @since 2.8.0
        class RowSelectorByLambda
          # @param conditions [Lambda] selection logic
          def initialize(conditions:, sep: nil)
            @conditions = conditions
          end

          def call(origrow:, mergerows:)
            conditions.call(origrow, mergerows)
          end

          private

          attr_reader :conditions
        end
      end
    end
  end
end
