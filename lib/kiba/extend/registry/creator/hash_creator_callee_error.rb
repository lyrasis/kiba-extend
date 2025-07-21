# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      class Creator
        class HashCreatorCalleeError < Kiba::Extend::Error
          def initialize(callee)
            super("Registry::Creator passed Hash with #{callee.class} "\
                  "`callee`. Give Method or Module instead.")
          end
        end
      end
    end
  end
end
