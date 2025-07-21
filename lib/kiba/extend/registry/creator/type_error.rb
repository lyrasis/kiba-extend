# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      class Creator
        # Raised when you try to initialize a Creator with an invalid type
        #   of creator
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
