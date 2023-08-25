# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      class Creator
        class HashCreatorCalleeError < Kiba::Extend::Error
          def initialize(callee)
            # rubocop:todo Layout/LineLength
            super("Registry::Creator passed Hash with #{callee.class} `callee`. Give Method or Module instead.")
            # rubocop:enable Layout/LineLength
          end
        end
      end
    end
  end
end
