# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations specific to preparing data for import into CollectionSpace
      module Cspace
        ::Cspace = Kiba::Extend::Transforms::Cspace
        # Characters or character combinations known to be treated strangely by CollectionSpace when creating IDs. Used as a lookup to force the substitution we need
        BRUTEFORCE = {
          'ș' => 's',
          't̕a' => 'ta'
        }.freeze
      end
    end
  end
end
