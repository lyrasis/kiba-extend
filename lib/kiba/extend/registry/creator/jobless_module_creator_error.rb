# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      class Creator
        # rubocop:todo Layout/LineLength
        # Raised when you try to initialize a Creator with an invalid value (wrong class)
        # rubocop:enable Layout/LineLength
        class JoblessModuleCreatorError < Kiba::Extend::Error
          def initialize(spec)
            # rubocop:todo Layout/LineLength
            super("#{spec} passed as Registry::Creator, but does not define `job` method")
            # rubocop:enable Layout/LineLength
          end
        end
      end
    end
  end
end
