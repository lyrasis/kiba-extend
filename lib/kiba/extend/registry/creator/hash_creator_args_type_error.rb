# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      class Creator
        class HashCreatorArgsTypeError < Kiba::Extend::Error
          def initialize(args)
            super("Registry::Creator passed Hash with #{args.class} `args`. Give a Hash instead.")
          end
        end
      end
    end
  end
end
