# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      module Lookup
        # Called by transforms that have a `conditions` parameter, when a Lambda is passed in as the
        #   conditions. This is a more straightforward and flexible method of controlling which rows
        #   are selected/operated on than the hideous Hash conditions format.
        #
        # The Lambda passed in must be defined with two arguments. The first should be a single
        #   data row, typically the source/target row for a data merge or other operation. The
        #   second is an array of data rows.
        #
        # Because of how this RowSelector is called by different transforms, both arguments need to be
        #   defined, even if you aren't going to use them in the logic encapsulated in the Lambda.
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
        #   fieldmap: { address: :display_address, addresstype: address_category },
        #   conditions: conditions
        # ```
        #
        # Assuming `addressid` increments as new addresses are added, sorting
        #   the matching lookup rows by that field value, and taking the last (largest) value
        #   should ensure we are merging in only the lastest address value per contact.
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
        #   fieldmap: { address: :display_address, addresstype: address_category },
        #   conditions: conditions
        # ```
        #
        # This assumes the source table (listing contacts) indicates whether a contact is active or not.
        #   In addition, the addresses table indicates whether each address is active. This will cause
        #   no addresses to be merged in for inactive contacts. For active contacts, only active
        #   addresses will be merged in.
        #
        # In your job transforms:
        #
        # ```
        # condition = ->(row, _x){ row.select{ |r| r[:note].match?(/gift|donation/i) } }
        # transform Merge::ConstantValueConditional, 
        #   fieldmap: { reason: 'gift' },
        #   conditions: condition
        # ```
        #
        # This will merge the constant value `gift` into the `reason` field if the `note` field includes `gift`
        #   or `donation` (case insensitive).
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

  
