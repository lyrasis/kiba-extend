# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Tranforms to add or decode a hashed row fingerprint field
      # @since 2.7.1.65
      module Fingerprint
        ::Fingerprint = Kiba::Extend::Transforms::Fingerprint
      end
    end
  end
end
