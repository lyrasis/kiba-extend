# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      class Creator
        class HashCreatorKeyError < Kiba::Extend::Error
          def initialize
            super("Registry::Creator passed Hash with no `callee` key")
          end
        end
      end
    end
  end
end
