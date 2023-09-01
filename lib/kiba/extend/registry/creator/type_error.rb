# frozen_string_literal: true

# rubocop:todo Layout/LineLength

module Kiba
  module Extend
    module Registry
      class Creator
        # Raised when you try to initialize a Creator with an invalid value (wrong class)
        class TypeError < Kiba::Extend::Error
          def initialize(spec)
            type = spec.class.to_s
            super("Registry::Creator cannot be called with #{type} (#{spec})")
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
