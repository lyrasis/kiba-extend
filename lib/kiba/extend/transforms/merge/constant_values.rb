# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Merge
        # @since 2.9.0
        #
        # Merges the given constant values into the given target fields.
        #
        # rubocop:todo Layout/LineLength
        # @note Uses {Kiba::Extend::Transforms::Merge::ConstantValue} to handle each pair in the `constantmap`, so
        # rubocop:enable Layout/LineLength
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
        # rubocop:todo Layout/LineLength
        # {name: 'Weddy', species_common: 'guinea fowl', species_binomial: 'Numida meleagris' },
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {name: 'Kernel', species: 'Numida meleagris', species_common: 'guinea fowl', species_binomial: 'Numida meleagris' }
        # rubocop:enable Layout/LineLength
        # ```
        #
        class ConstantValues
          def initialize(constantmap:)
            @mergers = constantmap.map do |target, value|
              Merge::ConstantValue.new(target: target, value: value)
            end
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            mergers.each { |merger| merger.process(row) }
            row
          end

          private

          attr_reader :mergers
        end
      end
    end
  end
end
