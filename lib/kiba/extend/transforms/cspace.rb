# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations specific to preparing data for import into CollectionSpace
      #
      # ## Other transforms of special relevance to CollectionSpace jobs
      #
      # - {Append::ConvertedValueAndUnit} - For augmenting Object dimension values
      # - {Name} transforms for Person authorities
      # - {Fingerprint} transforms for preparing cleanup worksheets for clients and merging completed worksheets
      #   back into migration projects
      # - {Reshape::CollapseMultipleFieldsToOneTypedFieldPair} - often useful for preparing phone type and email
      #   type fields
      # - {CombineValues::AcrossFieldGroup} and {Collapse::FieldsToRepeatableFieldGroup} - different approaches to
      #   generating data for repeatable field groups. {CombineValues::AcrossFieldGroup} makes sense if the data
      #   to be combined exists in basically the right "shape" for combining. You can just define what source
      #   fields map to what target fields without renaming fields in a particular way. When you have to
      #   explode/reshape/create source data into a combinable form, and you can do that buy creating fields
      #   using a consistent naming convention, {Collapse::FieldsToRepeatableFieldGroup} is a simpler transform
      #   to set up, and applies {Clean::EmptyFieldGroups} automatically
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
