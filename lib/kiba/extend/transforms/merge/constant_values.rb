# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Merge
        # @since 2.9.0
        #
        # Merges the given constant values into the given target fields.
        #
        # @note Uses {Kiba::Extend::Transforms::Merge::ConstantValue} to handle each pair in the `constantmap`, so
        #   check its behavior as well.
        #
        # ## Example
        # Source data:
        #
        # ```
        # {name: 'Weddy'},
        # {name: 'Kernel', species: 'Numida meleagris'}
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Merge::ConstantValues,
        #   constantmap: {
        #     species_common: 'guinea fowl',
        #     species_binomial: 'Numida meleagris'
        #   }
        # ```
        #
        # Results in:
        #
        # ```
        # {name: 'Weddy', species_common: 'guinea fowl', species_binomial: 'Numida meleagris' },
        # {name: 'Kernel', species: 'Numida meleagris', species_common: 'guinea fowl', species_binomial: 'Numida meleagris' }
        # ```
        #
        class ConstantValues
          def initialize(constantmap:)
            @mergers = constantmap.map{ |target, value| Merge::ConstantValue.new(target: target, value: value) }
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            mergers.each{ |merger| merger.process(row) }
            row
          end

          private

          attr_reader :mergers
        end
      end
    end
  end
end
