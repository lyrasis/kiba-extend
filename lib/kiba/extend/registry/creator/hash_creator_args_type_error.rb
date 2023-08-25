# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      class Creator
        class HashCreatorArgsTypeError < Kiba::Extend::Error
          def initialize(args)
            # rubocop:todo Layout/LineLength
            super("Registry::Creator passed Hash with #{args.class} `args`. Give a Hash instead.")
            # rubocop:enable Layout/LineLength
          end
        end
      end
    end
  end
end
