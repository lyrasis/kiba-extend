# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      # Value object representing a {Kiba::Extend::Registry::RegistryEntry}
      #   being used as a dynamic source
      class DynamicSource < RegisteredFile
        include Ancestorable

        def initialize(key:, for_job:, data: nil)
          super
        end
      end
    end
  end
end
