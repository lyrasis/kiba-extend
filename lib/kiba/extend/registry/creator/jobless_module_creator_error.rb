# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      class Creator
        # Raised when you try to initialize a Creator with an invalid value (wrong class)
        class JoblessModuleCreatorError < Kiba::Extend::Error
          def initialize(spec)
            super("#{spec} passed as Registry::Creator, but does not define `job` method")
          end
        end
      end
    end
  end
end
